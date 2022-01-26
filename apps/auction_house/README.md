# AuctionHouse

This is a Runtime Library (a library with GenServers) that manages the requests to the `warframe.market` Auction House. 

## How to use it?

This project is **not** an OTP application, meaning that to use it you need to include it in the Supervision tree of your application as one of its children.

```elixir
children = [
  {AuctionHouse, %{"cookie" => "a_cookie", "token" => "a_token"}},
  # ...
]
Supervisor.init(children, strategy: :one_for_one)
```

The library takes a map as a `credentials` parameter (as seen above) with the following format:

```elixir
  @type credentials :: %{
    (cookie :: String.t) => String.t,
    (token :: String.t) => String.t
  }
```
Without this, the `auction_house` library's `GenServer` cannot be started.

Why is this not an OTP application? Well, because it doesn't need to.
This Library is not supposed to handle the weight of the world. It is only supposed to Manage requests and responses to a website. That's it. 
It just so happens that doing so creates some Non Functional requirements and that is why we have GenServer's to deal with them. 

Because of this if you want to play around with this project you must first start the `GenServer` and then use the Public API to play around.

This application is used by the `manager` library.
The dependencies graph can be seen as follows:

![dependencies-graph](./dependencies.svg)

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
    {:auction_house, in_umbrella: true}
  ]
end
```

And then in your `config/config.exs` (or equivalent):

```elixir
config :auction_house,
  api_base_url: "http://localhost:8081/v1/profile/orders",
  api_search_url: "http://localhost:8081/v1/items"
```
