# Manager

This is a Runtime Library (a library with GenServers) that serves as the entry point for everything else. 
If you have an application that needs the functionalities offered by MarketManager, this is the one thing you need to 
import.

## How to use it?

This project is **not** an OTP application, meaning that to use it you need to include it in the Supervision tree of 
your application as one of its children.

```elixir
children = [
  Manager,
  # ...
]
Supervisor.init(children, strategy: :one_for_one)
```

Like with the `auction_house` library, this one is not an application because it doesn't need to be one.
As such, if you want to play around with this project you must first start the `GenServer` and then use the Public API.

As the entry point for everything else, this library's dependency graph is pretty much the same you saw in the main 
README file:

```mermaid
  graph TD;
      web_interface--uses-->manager
      manager--uses-->auction_house
      manager--uses-->store
      manager--uses-->shared
```

## Developer Guide

### Testing


You can execute the tests by running:

 - `mix deps.get`
 - `mix test`


### Usage

To use this library into your project, simply add it to your `mix.exs`:

```elixir
def deps do
  [
    {:manager, in_umbrella: true}
  ]
end
```