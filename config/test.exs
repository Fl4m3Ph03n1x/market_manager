import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :web_interface, WebInterface.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "0wO2E46q8MBY9aKZIowrNzjwJfzefGx7o94dtvYpidIK81uZxDOCLHAgKOhHQwLx",
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :web_interface, WebInterface.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "A6xbGasiCzawAwCjBQW6eO2ExEbRWykU57rU+NmdiP3qugMGTg7XqPIsmxveodFz",
  server: false

config :store,
  products: "products.json",
  current_orders: "current_orders.json",
  setup: "setup.json"

config :auction_house,
  api_base_url: "http://localhost:8082/v1/profile/orders",
  api_search_url: "http://localhost:8082/v1/items",
  market_signin_url: "http://localhost:8082/auth/signin",
  api_signin_url: "http://localhost:8082/v1/auth/signin",
  http_response_timeout: 2_000,
  genserver_timeout: 5_000
