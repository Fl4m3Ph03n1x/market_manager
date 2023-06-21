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
  secret_key_base: "zcj4AcOdKlg85KJdcbu+hNEjoZCial47L6J6mqweRKQ6t/KfPGDA/wP6fDk2vt3H",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/web_interface/(controllers|live|components|views)/.*(ex|heex)$",
      ~r"lib/web_interface/templates/.*(eex)$"
    ]
  ],
  # Enable dev routes for dashboard and mailbox
  dev_routes: true

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
