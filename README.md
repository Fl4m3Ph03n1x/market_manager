![Build Status](https://github.com/Fl4m3Ph03n1x/market_manager/workflows/build/badge.svg?branch=master) [![Coverage Status](https://coveralls.io/repos/github/Fl4m3Ph03n1x/market_manager/badge.svg?branch=master)](https://coveralls.io/github/Fl4m3Ph03n1x/market_manager?branch=master)

# MarketManager

Makes sell requests in batch to warframe market.
Used when you want to sell a lot of things or remove them from your list all at
once. Specially usefull for syndicates because you dont have to buy everything
in advance and if you want to avoid the 100 items limit without being a Patreon,
which if you want to support the site, you should totally become.

## Setup

Before using this application you need to get access to two things:
1. x-rfctoken from warframe.market
2. a cookie from warframe.market

To get both of them you can:
1. Login with your account to warframe.market
2. Set you status to "Invisible"
3. Go to "My profile"
4. Click "Place order" button and fill in the form, BUT DO NOT PRESS "POST"
5. Using your favorite browser enter the developer's console (usually by pressing F12)
6. Go to the network section of the developer's console, clear it (if it has previous logs) and start monitoring
7. Press the "POST" button on the form
8. The console should have logged a POST request to the website
9. Inspect the request and look for "Request headers"
10. Copy the cookie and the token to somewhere

Once you have the cookie and the token, you need to set the follow environment variables in your machine:
- MARKET_MANAGER_WM_COOKIE={cookie}
- MARKET_MANAGER_WM_XCSRFTOKEN={xrfctoken}

Where {cookie} and {token} are the cookie and the xrfctoken you got from the website previously.

## Usage

Place the things you want to sell under a file called `products.json`. This file
should contain a list of objects, each one with an array of things to sell:

It only supports mods currently.

```json
{
    "red_veil": [
        {
            "name": "Gleaming Blight",
            "id": "54a74454e779892d5e5155d5",
            "price": 15
        },
        {
            "name": "Eroding Blight",
            "id": "54a74454e779892d5e5155a0",
            "price": 15
        }
    ],
    "new_loka": [
        {
            "name": "Winds of purity",
            "id": "54a74455e779892d5e51569a",
            "price": 15
        },
        {
            "name": "Disarming purity",
            "id": "5911f11d97a0add8e9d5da4c",
            "price": 15
        }
    ]
}
```

The format of each item is the following:

```
{
  "name": "Disarming purity",       //name of the item
  "id": "5911f11d97a0add8e9d5da4c", //warframe.market item id
  "price": 15,                      //platinum price of the item
  "rank": 1,                        //rank of the mod, defaults to 0. If the mod has no rank use "n/a" instead
  "quantity": 1                     //number of items to sell, defaults to 1
}
```

Once you have the `products.json` file set up, you can use the shell application:

```
./market_manager --action=activate --syndicates=red_veil,new_loka
```

The name of the syndicates must be the same name on the `products.json` file.

For more information on how to use type:

```
./market_manager -h
```

## Development

This project has a dependency erlang 22.1. While it doesn't require a lot of memory to run, it does require a lot of memory to compile, at least 4GB.

Some of the dependencies also require rebar3 to work. Sometimes it is problematic to install rebar3 so, this script for Linux does the job:

```
curl -O https://rebar3.s3.amazonaws.com/rebar3 -k
rm -rf /root/.mix/rebar3
mv rebar3 /root/.mix/
mix local.rebar rebar3 /root/.mix/rebar3 --force
```

After the initial setup, the following commands are used to run the tests:
- `mix test` run all tests
- `mix test.unit` runs only unit tests
- `mix test.integration` runs only integration tests
- `mix test.watch` runs all tests continuously and re-runs them every time a file changes
- `mix test.watch.unit` runs unit tests continuously and re-runs them every time a file changes
- `mix test.watch.integration` runs integration tests continuously and re-runs them every time a file changes
