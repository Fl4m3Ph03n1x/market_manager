import Config

config :market_manager,
  auction_house_api: MarketManager.AuctionHouse.HTTPClient,
  api_base_url: "https://api.warframe.market/v1/profile/orders"

