defmodule RateLimiter do
  @moduledoc """
  Interface for a rate limiter. Based from:
  https://akoutmos.com/post/rate-limiting-with-genservers/
  """

  @milliseconds_in_second 1000
  @algorithm Application.compile_env!(:rate_limiter, :algorithm)
  @rps Application.compile_env!(:rate_limiter, :requests_per_second)

  @type response :: any()
  @type request_arguments :: [any()]
  @type metadata :: map()
  @type response_function :: (response(), metadata() -> any())

  @type request_handler :: {(... -> response()), request_arguments()}
  @type response_handler :: {response_function(), metadata()}

  @callback make_request(request_handler(), response_handler()) :: :ok

  @doc """
  Default implementation for the make_request function of this behaviour. Fetches the limiter of choice from configs.
  """
  def make_request(request_handler, response_handler),
    do: get_rate_limiter().make_request(request_handler, response_handler)

  @doc """
  Gets the limiter from the configs at compile time.
  """
  def get_rate_limiter, do: @algorithm

  @doc """
  Gets the requests per second from the configs at compile time.
  """
  def get_requests_per_second, do: @rps

  @doc """
  Calculates the refresh rate, to determine how many requests per second the limiter can made.
  """
  def calculate_refresh_rate(num_requests), do: floor(@milliseconds_in_second / num_requests)
end
