import Config

config :market_manager,
  products: "test/support/products.json",
  current_orders: "test/support/current_orders.json",
  api_base_url: "http://localhost:8082/v1/profile/orders",
  api_search_url: "http://localhost:8082/items",
  auction_house_cookie: "cookie",
  auction_house_token: "token"
