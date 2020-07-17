import Config

config :market_manager,
  auction_house_cookie: System.fetch_env!("MARKET_MANAGER_WM_COOKIE"),
  auction_house_token: System.fetch_env!("MARKET_MANAGER_WM_XCSRFTOKEN")

import_config "#{Mix.env()}.exs"
