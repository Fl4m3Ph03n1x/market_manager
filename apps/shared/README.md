# Shared

This is a Functional Library that holds general utility functions used across 
all the project. 

It also holds the DataStructures and Types used to represent the Domain. 

As you can see from below, every app depends on this library.

![dependencies-graph](./store_logic.svg)

## Developer Guide

This project uses Gradient as a static type checking tool. This means there 
may be con conflicts with other tools, but this is being worked on. 

### Testing

Since this is a functional library, there are only unit tests. You can run them
via `mix test`.

### Usage

To use this library into your project, simply add it to your `mix.exs`:

```elixir
def deps do
  [
    {:shared, in_umbrella: true}
  ]
end
```
