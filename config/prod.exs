import Config

config :market_manager,
  products: "products.json",
  current_orders: "current_orders.json",
  api_search_url: "https://warframe.market/items",
  api_base_url: "https://api.warframe.market/v1/profile/orders",
  auction_house_cookie: System.fetch_env!("MARKET_MANAGER_WM_COOKIE"),
  auction_house_token: System.fetch_env!("MARKET_MANAGER_WM_XCSRFTOKEN")
