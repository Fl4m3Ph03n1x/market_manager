import Config

config :market_manager,
  auction_house_api: MarketManager.AuctionHouse.HTTPClient,
  store_api: MarketManager.Store.FileSystem,
  products: "products.json",
  current_orders: "current_orders.json",
  api_base_url: "https://api.warframe.market/v1/profile/orders"

