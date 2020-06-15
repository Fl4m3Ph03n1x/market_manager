import Config

config :market_manager,
  auction_house_api: MarketManager.AuctionHouse.HTTPClient,
  store_api: MarketManager.Store.FileSystem,
  products: "test/`products.json",
  current_orders: "test/current_orders.json",
  api_base_url: "http://localhost:8081"

