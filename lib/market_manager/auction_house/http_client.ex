defmodule MarketManager.AuctionHouse.HTTPClient do
  @moduledoc """
  Adapter for the interface AuctionHouse
  """

  use Rop

  alias MarketManager.AuctionHouse

  @behaviour AuctionHouse

  @url Application.compile_env!(:market_manager, :api_base_url)
  @headers [
    {"User-Agent",
     "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:76.0) Gecko/20100101 Firefox/76.0"},
    {"Accept", "application/json"},
    {"Accept-Language", "en-US,en;q=0.5"},
    {"Content-Type", "application/json"},
    {"language", "en"},
    {"platform", "pc"},
    {"x-csrftoken",
     "##12ecacf698f99616bd5ed5cc11a339aeda3af8d22d667583688d9d89be281bb1ad89a6dd5036a407259d12bc0311f6b4991b892eb178a8c8cf6cf9a50e009ff2"},
    {"Origin", "https://warframe.market"},
    {"DNT", "1"},
    {"Connection", "keep-alive"},
    {"Cookie",
     "__cfduid=dafc34ba816bcebf538279e5538d16f611586856929; JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJnTzFSWnpXS0pEM0dwTW56MzlzQTdjbXRmeVVrNjg4VCIsImNzcmZfdG9rZW4iOiIwNGVjNmU0MWIyYTg1N2NiNTYxNzJlOTViMjk1NjMxYzVhZTEyN2FlIiwiZXhwIjoxNTk0NDY0MTQ5LCJpYXQiOjE1ODkyODAxNDksImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6ZmFsc2UsImxvZ2luX3VhIjoiYidNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMC4xNDsgcnY6NzYuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC83Ni4wJyIsImxvZ2luX2lwIjoiYic4MC43MS4wLjIwOSciLCJqd3RfaWRlbnRpdHkiOiJCZFdQR3F4WlU1RW56SUJXUDhHU3VYNEhBNE84RVlDUSJ9.Ua8qXU-yY56KVBv_PsVhflmHQizM3DNI_gG5vwlOJj4"},
    {"TE", "Trailers"}
  ]

  @default_deps [
    post_fn: &HTTPoison.post/3,
    delete_fn: &HTTPoison.delete/2
  ]

  ##########
  # Public #
  ##########

  @impl AuctionHouse
  def place_order(order, deps \\ @default_deps) do
    http_post = deps[:post_fn]

    {:ok, encoded_order} = Jason.encode(order)
    response = http_post.(@url, encoded_order, @headers)

    case response do
      {:ok, %HTTPoison.Response{status_code: 400, body: error_body}} ->
        error_body
        |> Jason.decode!()
        |> map_error()
        |> build_error_response(order)

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> get_id()
        |> build_success_response()

      {:error, %HTTPoison.Error{id: _id, reason: reason}} ->
        build_error_response({:error, reason}, order)
    end

    # post_order = fn order ->
    #   deps[:post_fn].(@url, order, @headers)
    # end

    # Jason.encode(order)
    # >>> post_order()
    # >>> to_auction_house_response
  end

  @impl AuctionHouse
  def delete_order(order_id, deps \\ @default_deps) do
    http_delete = deps[:delete_fn]

    response =
      order_id
      |> build_delete_url()
      |> http_delete.(@headers)

    case response do
      {:ok, %HTTPoison.Response{status_code: 400, body: error_body}} ->
        error_body
        |> Jason.decode!()
        |> map_error()
        |> build_error_response(order_id)

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> get_id()
        |> build_success_response()

      {:error, %HTTPoison.Error{id: _id, reason: reason}} ->
        build_error_response({:error, reason}, order_id)
    end
  end

  ###########
  # Private #
  ###########

  @spec map_error(error_response :: map) :: {:error, :invalid_item_id | :order_already_placed | :order_non_existent | :rank_level_non_applicable}
  defp map_error(%{"error" => %{"item_id" => _error}}), do: {:error, :invalid_item_id}

  defp map_error(%{"error" => %{"_form" => _error}}), do: {:error, :order_already_placed}

  defp map_error(%{"error" => %{"order_id" => _error}}), do: {:error, :order_non_existent}

  defp map_error(%{"error" => %{"mod_rank" => _error}}), do: {:error, :rank_level_non_applicable}

  @spec get_id(response :: map) :: AuctionHouse.order_id() | AuctionHouse.item_id()
  defp get_id(%{"payload" => %{"order" => %{"id" => id}}}), do: id
  defp get_id(%{"payload" => %{"order_id" => id}}), do: id

  @spec build_success_response(AuctionHouse.order_id()) :: {:ok, AuctionHouse.order_id()}
  defp build_success_response(id), do: {:ok, id}

  @spec build_error_response({:error, reason :: atom}, AuctionHouse.order_id() | AuctionHouse.order()) ::
          {:error, reason :: atom, AuctionHouse.order_id() | AuctionHouse.item_id()}
  defp build_error_response({:error, reason}, order) when is_map(order),
    do: {:error, reason, Map.get(order, "item_id")}

  defp build_error_response({:error, reason}, order_id) when is_binary(order_id),
    do: {:error, reason, order_id}

  @spec build_delete_url(AuctionHouse.order_id()) :: (url :: String.t())
  defp build_delete_url(id), do: @url <> "/" <> id
end
