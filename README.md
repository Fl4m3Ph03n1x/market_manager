# MarketManager

Makes sell requests in batch to warframe market. 
Used when you want to sell a lot of things or remove them from your list all at 
once. Specially usefull for syndicates because you dont have to buy everything 
in advance and if you want to avoid the 100 items limit without being a Patreon,
which if you want to support the site, you should totally become.

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
  "rank": 1,                        //rank of the mod. Defaults to 0
  "quantity": 1                     //number of items to sell. Defaults to 1
}
```

Once you have the `products.json` file set up, you can use the shell appliaction:

```
./market_manager --action=activate --syndicates=red_veil,new_loka
```

The name of the syndicates must be the same name on the `products.json` file.

For more information on how to use type:

```
./market_manager -h
```

