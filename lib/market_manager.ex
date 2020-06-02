defmodule MarketManager do
  @moduledoc """
  Documentation for MarketManager.
  """

  @url "https://api.warframe.market/v1/profile/orders"
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
  @orders_filename "current_orders.json"
  @products_filename "products.json"

  def activate(syndicate) do
    with {:ok, file} <- File.open(@products_filename, [:read]),
         {:ok, content} <- File.read(@products_filename),
         :ok <- File.close(file),
         {:ok, decoded_body} <- Jason.decode(content),
         {:ok, syndicate_products} <- find_syndicate(decoded_body, syndicate),
         {success_resps, failed_resps} <- make_requests(syndicate_products) do
      {:ok, orders_file} = File.open(@orders_filename, [:write])

      order_ids =
        Enum.map(
          success_resps,
          fn {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            with {:ok, decoded_body} <- Jason.decode(body),
                 {:ok, id} <- get_id(decoded_body) do
              id
            end
          end
        )

      {:ok, orders_json} = Jason.encode(%{
        syndicate => order_ids
      })

      :ok = File.write(@orders_filename, orders_json)
      :ok = File.close(orders_file)

      if Enum.empty?(success_resps) do
        {:error, :unable_to_place_requests, failed_resps}
      else
        case Enum.empty?(failed_resps) do
          true -> {:ok, :success}
          false -> {:partial_success, order_ids, failed_resps}
        end
      end
    end
  end

  defp find_syndicate(json, syndicate_name) do
    if Map.has_key?(json, syndicate_name) do
      {:ok, Map.get(json, syndicate_name)}
    else
      {:error, :syndicate_not_found, syndicate_name}
    end
  end

  defp make_requests(products) do
    all_responses =
      Enum.map(products, fn product ->
        {:ok, order} =
          Jason.encode(%{
            "order_type" => "sell",
            "item_id" => Map.get(product, "id"),
            "platinum" => Map.get(product, "price"),
            "quantity" => Map.get(product, "quantity", 1),
            "mod_rank" => Map.get(product, "rank", 0)
          })

        HTTPoison.post(@url, order, @headers)
      end)

    Enum.split_with(all_responses, fn {status, _resp} -> status == :ok end)
  end

  def deactivate(syndicate) do
    with {:ok, file} <- File.open(@orders_filename, [:read]),
         {:ok, content} <- File.read(@orders_filename),
         {:ok, decoded_body} <- Jason.decode(content),
         {:ok, orders_json} <- find_syndicate(decoded_body, syndicate),
         delete_urls <- build_urls(orders_json),
         {success_resps, failed_resps} <- make_delete_requests(delete_urls),
         :ok <- File.close(file) do

          order_ids =
            Enum.map(
              success_resps,
              fn {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                with {:ok, decoded_body} <- Jason.decode(body),
                     {:ok, id} <- get_id(decoded_body) do
                  id
                end
              end
            )

          if Enum.empty?(success_resps) do
            {:error, :unable_to_delete_orders, failed_resps}
          else
            case Enum.empty?(failed_resps) do
              true -> {:ok, :success}
              false -> {:partial_success, order_ids, failed_resps}
            end
          end
    end
  end

  defp build_urls(ids), do: Enum.map(ids, fn id -> @url <> "/" <> id end)

  defp make_delete_requests(urls) do
    all_responses =
      Enum.map(urls, fn delete_url ->
        HTTPoison.delete(delete_url, @headers)
      end)

    Enum.split_with(all_responses, fn {status, _resp} -> status == :ok end)
  end

  defp get_id(decoded_body) do
    case get_in(decoded_body, ["payload", "order", "id"]) do
      id when is_binary(id) -> {:ok, id}
      _ -> {:error, :order_id_not_found, decoded_body}
    end
  end
end
