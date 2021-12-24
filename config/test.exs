import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :web_interface, WebInterface.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "2fIHOTb8jCA0CVlj7aVEvX86YfuvOJsAm5e3LtgghWBunpqO/HTMds2UZX6Rgwfw",
  server: false
