import Config
import_config "test.exs"

# Here's where the two testing environments differ so that Mox is configured correctly:
config :market_manager,
  auction_house_api: MarketManager.AuctionHouse.HTTPClient,
  store_api: MarketManager.Store.FileSystem
