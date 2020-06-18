import Config

config :market_manager,
  auction_house_api: MarketManager.AuctionHouseMock,
  store_api: MarketManager.StoreMock,
  products: "test/support/products.json",
  current_orders: "test/support/current_orders.json",
  api_base_url: "http://localhost:8082/v1/profile/orders"
