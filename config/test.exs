import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :web_interface, WebInterface.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "A6xbGasiCzawAwCjBQW6eO2ExEbRWykU57rU+NmdiP3qugMGTg7XqPIsmxveodFz",
  server: true,
  check_origin: false

config :store,
  products: Path.expand("#{__DIR__}/../apps/store/test/fixtures/products.json") |> Path.split(),
  current_orders:
    Path.expand("#{__DIR__}/../apps/store/test/fixtures/current_orders.json") |> Path.split(),
  setup: Path.expand("#{__DIR__}/../apps/store/test/fixtures/setup.json") |> Path.split(),
  syndicates:
    Path.expand("#{__DIR__}/../apps/store/test/fixtures/syndicates.json") |> Path.split()

config :auction_house,
  api_base_url: "http://localhost:8082/v1/profile/orders",
  api_search_url: "http://localhost:8082/v1/items",
  market_signin_url: "http://localhost:8082/auth/signin",
  api_signin_url: "http://localhost:8082/v1/auth/signin",
  api_profile_url: "http://localhost:8082/v1/profile",
  http_response_timeout: 2_000,
  genserver_timeout: 5_000
