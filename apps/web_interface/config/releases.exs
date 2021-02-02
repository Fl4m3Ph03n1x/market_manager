# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

secret_key_base = "fNLUlX9B2V22b4mc74qrvWcod6auRthTAz2+E5M/DUL7B+S/WsxQzQBhIXnElayt"

config :web_interface, WebInterfaceWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "80"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :web_interface, WebInterfaceWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
