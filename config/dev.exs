import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :web_interface, WebInterface.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "IE2g7HAQ0s10uSNkFPeqAaDXa1OIJQxshR/1lSBDOsB1Ol3ytpeP4UiTiF2ekZ6a",
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]

# Watch static and templates for browser reloading.
config :web_interface, WebInterface.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/web_interface/(live|views)/.*(ex)$",
      ~r"lib/web_interface/templates/.*(eex)$"
    ]
  ]

# Files will be DELETED after running integration tests!
config :store,
  products: "../../test_setup/products.json",
  current_orders: "../../test_setup/current_orders.json",
  setup: "../../test_setup/setup.json"

config :auction_house,
  api_search_url: "http://localhost:8082/v1/items",
  api_base_url: "http://localhost:8082/v1/profile/orders",
  market_signin_url: "http://localhost:8082/auth/signin",
  api_signin_url: "http://localhost:8082/v1/auth/signin",
  http_response_timeout: 9_000,
  genserver_timeout: 20_000
