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

config :store,
  products: Path.expand("#{__DIR__}/../apps/store/test/fixtures/products.json") |> Path.split(),
  current_orders:
    Path.expand("#{__DIR__}/../apps/store/test/fixtures/current_orders.json") |> Path.split(),
  setup: Path.expand("#{__DIR__}/../apps/store/test/fixtures/setup.json") |> Path.split(),
  syndicates:
    Path.expand("#{__DIR__}/../apps/store/test/fixtures/syndicates.json") |> Path.split()

config :auction_house,
  api_search_url: "http://localhost:8082/v1/items",
  api_base_url: "http://localhost:8082/v1/profile/orders",
  market_signin_url: "http://localhost:8082/auth/signin",
  api_signin_url: "http://localhost:8082/v1/auth/signin",
  api_profile_url: "http://localhost:8082/v1/profile",
  http_response_timeout: 9_000,
  genserver_timeout: 20_000

config :rate_limiter,
  algorithm: RateLimiter.LeakyBucket,
  requests_per_second: 1
