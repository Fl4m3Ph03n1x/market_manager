defmodule RateLimiter do
  @moduledoc """

  """

  @milliseconds_in_second 1000
  @algorithm Application.compile_env!(:rate_limiter, :algorithm)
  @rps Application.compile_env!(:rate_limiter, :requests_per_second)

  @type response :: any()
  @type request_arguments :: [any()]
  @type metadata :: map()
  @type reponse_function :: (response(), metadata() -> any())

  @type request_handler :: {(... -> response()), request_arguments()}
  @type response_handler :: {reponse_function(), metadata()}

  @callback make_request(request_handler(), response_handler()) :: :ok

  def make_request(request_handler, response_handler),
    do: get_rate_limiter().make_request(request_handler, response_handler)

  def get_rate_limiter, do: @algorithm
  def get_requests_per_second, do: @rps

  def calculate_refresh_rate(num_requests), do: floor(@milliseconds_in_second / num_requests)
end
