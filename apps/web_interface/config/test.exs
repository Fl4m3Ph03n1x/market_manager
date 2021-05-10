import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :web_interface, WebInterfaceWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :store,
  products: "test/products.json",
  current_orders: "test/current_orders.json",
  setup: "test/setup.json"

config :auction_house,
  api_base_url: "http://localhost:8081/v1/profile/orders",
  api_search_url: "http://localhost:8081/v1/items",
  auction_house_cookie: "cookie",
  auction_house_token: "token"
