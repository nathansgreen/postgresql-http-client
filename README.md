# postgresql-http-client [![CircleCI](https://circleci.com/gh/NikolayS/postgresql-http-client/tree/master.svg?style=svg)](https://circleci.com/gh/NikolayS/postgresql-http-client/tree/master)
Simple HTTP client inside your PostgreSQL. Easy to install. No compilation required: no gcc, no `make && make install`. Uses only standard extension available in any popular Linux distribution.

Works very fast ([see details](https://github.com/NikolayS/postgresql-http-client/blob/master/benchmarks.md)).
BUT: :warning: be careful calling external/unpredictable resources, because the population of Postgres backends on your server is about of the same size as the population of [Siberian tigers](https://en.wikipedia.org/wiki/Siberian_tiger).

Allows GET and POSTS requests in SQL environment:

```sql
test=> \x
Expanded display is on.
test=> select (get).* from http_client.get('http://ya.ru');
-[ RECORD 1 ]--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
status_code | 302
status_line | HTTP/1.1 302 Found
headers     | {"P3P": "policyref=\"/w3c/p3p.xml\", CP=\"NON DSP ADM DEV PSD IVDo OUR IND STP PHY PRE NAV UNI\"", "Date": "Sat, 29 Oct 2016 00:08:43 GMT", "Server": "nginx", "Expires": "Sat, 29 Oct 2016 00:08:44 GMT", "Location": "https://ya.ru/", "Connection": "keep-alive", "Set-Cookie": "yandexuid=182183081477699724; Expires=Tue, 27-Oct-2026 00:08:43 GMT; Domain=.ya.ru; Path=/", "Cache-Control": "no-cache,no-store,max-age=0,must-revalidate", "Last-Modified": "Sat, 29 Oct 2016 00:08:44 GMT", "Content-Length": "0"}
body        |
is_json     | f
```

Another example, showing work with REST API:
```sql
test=> with results as (
  select jsonb_array_elements(get.body::jsonb->'results') as r
  from http_client.get('http://pokeapi.co/api/v2/pokemon/', '{"user-agent":"test-robot"}'::jsonb)
)
select r->>'url' as url, r->>'name' as pokename
from results
order by pokename
limit 5;
                 url                  |  pokename
--------------------------------------+------------
 http://pokeapi.co/api/v2/pokemon/15/ | beedrill
 http://pokeapi.co/api/v2/pokemon/9/  | blastoise
 http://pokeapi.co/api/v2/pokemon/1/  | bulbasaur
 http://pokeapi.co/api/v2/pokemon/12/ | butterfree
 http://pokeapi.co/api/v2/pokemon/10/ | caterpie
(5 rows)
```
