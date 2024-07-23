defmodule RateLimiter do
  @moduledoc """

  """

  @milliseconds_in_second 1000

  @type request_handler :: {module(), atom(), [any()]}
  @type response_handler :: {module(), atom()}

  @callback make_request(request_handler(), response_handler()) :: :ok

  def make_request(request_handler, response_handler),
    do: get_rate_limiter().make_request(request_handler, response_handler)

  # we do it with get_env to allow switching config with the app running
  def get_rate_limiter, do: Application.get_env(:rate_limiter, :algorithm)
  def get_requests_per_second, do: Application.get_env(:rate_limiter, :requests_per_second)

  def calculate_refresh_rate(num_requests), do: floor(@milliseconds_in_second / num_requests)

end
