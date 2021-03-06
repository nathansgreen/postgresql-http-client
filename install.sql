--
-- to install plpython:
-- apt-get install postgresql-plpython-9.5
--

begin;

drop schema if exists http_client cascade;

create schema http_client;

do $$
begin
    execute 'alter database '||current_database()||' set http_client.connect_timeout = 2;';
    execute 'alter database '||current_database()||' set http_client.default_headers = ''{}'';';
end;
$$ language plpgsql;

create type http_client.response as (
    url_requested text,
    url_received text,
    status_code integer,
    headers json,
    body text,
    is_json boolean
);

create or replace function http_client._get(url text, timeout integer, headers jsonb) returns http_client.response as $$
    from urllib2 import Request, urlopen, HTTPError
    import json

    res = {}
    res['url_requested'] = url
    res['body'] = res['status_code'] = res['url_received'] = None
    res['is_json'] = res['headers'] = None
    try:
        req = Request(url)
        if headers:
            for k, v in json.loads(headers).iteritems():
                req.add_header(k, v)
        conn = urlopen(req, timeout = timeout)
        res['body'] = conn.read()
        res['status_code'] = conn.getcode()
        res['url_received'] = conn.geturl()
        respHeaders = conn.info().dict
        conn.close()
    except HTTPError as e:
        res['status_code'] = e.code
        respHeaders = e.headers.dict # undocumented http://stackoverflow.com/a/6402083/4677351
        res['body'] = e.read()
    res['headers'] = json.dumps(respHeaders)
    if 'content-type' in respHeaders and respHeaders['content-type'].find('application/json') >= 0:
        res['is_json'] = True
    else:
        res['is_json'] = False
    return res
$$ language plpython2u volatile;

create or replace function http_client.get(query text, headers jsonb) returns http_client.response as $$
    select http_client._get(
        query,
        current_setting('http_client.connect_timeout')::integer,
        current_setting('http_client.default_headers')::jsonb || coalesce(headers, '{}'::jsonb)
    );
$$ language sql volatile;

create or replace function http_client.get(query text) returns http_client.response as $$
    select http_client.get(query, '{}'::jsonb);
$$ language sql volatile;

commit;
