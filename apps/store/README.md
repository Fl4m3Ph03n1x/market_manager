# Store

Library responsible for persisting data. It is functional (barring some configurations).
This library simply persist the data. No validations are done here. If incorrect data is given
to this library, then incorrect data will be persisted. 

## How is data persisted?

Right now data is being persisted by the module `Store.FileSystem`. `Store` is the public API, while the 
implementation currently under use is the `FileSystem`:


![dependencies-graph](./store_logic.svg)

`FileSystem` basically saves the data into disk files using JSON. It is not the most efficient approach, nor the fastest,
because it's not meant to. The main objective of this library is to persist data in a very simple way that can be audited by
a Human. Simplicity is the main goal and JSON files are a good human readable way to achieve that.

## Developer Guide

### Testing

The most important thing to mention here is that there are 2 main types of tests:
 - Unit
 - Integration

Unit tests have no side effects and use dummies. 
Integration tests do actually create and delete files and write in disk. 

You can execute them by running:

 - `mix deps.get`
 - `mix test`

### Usage

To use this library into your project, simply add it to your `mix.exs`:

```elixir
def deps do
  [
    {:store, in_umbrella: true}
  ]
end
```

And then in your `config/config.exs` (or equivalent):

```elixir
config :store,
  products: "path_to_products.json",
  current_orders: "path_to_current_orders.json",
  setup: "path_to_setup.json"
```
