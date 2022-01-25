import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :web_interface, WebInterface.Endpoint,
  http: [port: 80],
  url: [host: "localhost", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: "CCUaDp4htK08p5Uusqp5qUVBriyxaFqqREJeviYYArsfVXMsciGMv+ybS1A2rNoL",
  check_origin: false,
  server: true

config :store,
  products: "products.json",
  current_orders: "current_orders.json",
  setup: "setup.json"

config :auction_house,
  api_search_url: "https://api.warframe.market/v1/items",
  api_base_url: "https://api.warframe.market/v1/profile/orders"
