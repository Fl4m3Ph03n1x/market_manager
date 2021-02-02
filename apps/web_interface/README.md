# LiveView Demo

A demo app that lets you control a light bulb's intensity:

![screenshot](./liveview_demo.png?raw=true "screenshot")

Adapted from the tutorial [Getting Started with Phoenix LiveView](https://pragmaticstudio.com/tutorials/getting-started-with-phoenix-liveview)

# Getting started

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


The project is production ready:

  * Run `npm run deploy --prefix assets`
  * Digest the files `MIX_ENV=prod mix phx.digest`
  * Run `MIX_ENV=prod mix release`
  * Launch server with `_build/prod/rel/demo/bin/demo start`

For more information refer to the [deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more about Phoenix LiveView

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
