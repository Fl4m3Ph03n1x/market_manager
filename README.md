# MarketManager

Makes sell requests in batch to warframe market. 
Used when you want to sell a lot of things or remove them from your list all at
once. Specially usefull for syndicates because you dont have to buy everything 
in advance and if you want to avoid the 100 items limit without being a Patreon,
which if you want to support the site, you should totally become.

## Usage

Place the things you want to sell under a file called `products.json`. This file
should contain a list of objects, each one with an array of things to sell.

## Docs

Place an order curl:

```bash
    curl 'https://api.warframe.market/v1/profile/orders'
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:76.0) Gecko/20100101 Firefox/76.0'
    -H 'Accept: application/json'
    -H 'Accept-Language: en-US,en;q=0.5' --compressed
    -H 'Content-Type: application/json'
    -H 'language: en'
    -H 'platform: pc'
    -H 'x-csrftoken: ##12ecacf698f99616bd5ed5cc11a339aeda3af8d22d667583688d9d89be281bb1ad89a6dd5036a407259d12bc0311f6b4991b892eb178a8c8cf6cf9a50e009ff2'
    -H 'Origin: https://warframe.market'
    -H 'DNT: 1'
    -H 'Referer: https://warframe.market/items/gleaming_blight'
    -H 'Connection: keep-alive'
    -H 'Cookie: __cfduid=dafc34ba816bcebf538279e5538d16f611586856929; JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJnTzFSWnpXS0pEM0dwTW56MzlzQTdjbXRmeVVrNjg4VCIsImNzcmZfdG9rZW4iOiIwNGVjNmU0MWIyYTg1N2NiNTYxNzJlOTViMjk1NjMxYzVhZTEyN2FlIiwiZXhwIjoxNTk0NDY0MTQ5LCJpYXQiOjE1ODkyODAxNDksImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6ZmFsc2UsImxvZ2luX3VhIjoiYidNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMC4xNDsgcnY6NzYuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC83Ni4wJyIsImxvZ2luX2lwIjoiYic4MC43MS4wLjIwOSciLCJqd3RfaWRlbnRpdHkiOiJCZFdQR3F4WlU1RW56SUJXUDhHU3VYNEhBNE84RVlDUSJ9.Ua8qXU-yY56KVBv_PsVhflmHQizM3DNI_gG5vwlOJj4'
    -H 'TE: Trailers'
    --data-raw '{"order_type":"sell","item_id":"54a74454e779892d5e5155d5","platinum":15,"quantity":1,"mod_rank":0}'
```

Delete a request curl:

```bash
  curl 'https://api.warframe.market/v1/profile/orders/5ed623ab7d0c9a07bdef60b9'
    -X DELETE
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:76.0) Gecko/20100101 Firefox/76.0'
    -H 'Accept: application/json'
    -H 'Accept-Language: en-US,en;q=0.5'
    --compressed
    -H 'content-type: application/json'
    -H 'language: en'
    -H 'platform: pc'
    -H 'x-csrftoken: ##12ecacf698f99616bd5ed5cc11a339aeda3af8d22d667583688d9d89be281bb1ad89a6dd5036a407259d12bc0311f6b4991b892eb178a8c8cf6cf9a50e009ff2'
    -H 'Origin: https://warframe.market'
    -H 'DNT: 1'
    -H 'Referer: https://warframe.market/profile/Fl4m3Ph03n1x'
    -H 'Connection: keep-alive'
    -H 'Cookie: JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJnTzFSWnpXS0pEM0dwTW56MzlzQTdjbXRmeVVrNjg4VCIsImNzcmZfdG9rZW4iOiIwNGVjNmU0MWIyYTg1N2NiNTYxNzJlOTViMjk1NjMxYzVhZTEyN2FlIiwiZXhwIjoxNTk2Mjc2MTQ4LCJpYXQiOjE1OTEwOTIxNDgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6ZmFsc2UsImxvZ2luX3VhIjoiYidNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMC4xNDsgcnY6NzYuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC83Ni4wJyIsImxvZ2luX2lwIjoiYic4MC43MS4wLjIwOSciLCJqd3RfaWRlbnRpdHkiOiJCZFdQR3F4WlU1RW56SUJXUDhHU3VYNEhBNE84RVlDUSJ9.tule77vE038e08Em5zajfmmrEM1IU5n-dBMS8_ogWGI; __cfduid=db7b60c9babea93ae9b7d4b54302a6d8d1589531123'
    -H 'TE: Trailers'
```