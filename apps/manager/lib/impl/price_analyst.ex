defmodule Manager.Impl.PriceAnalyst do
  @moduledoc """
  Strategies calculate the optimum price for you to sell an item.

  There are several strategies, some focus more on selling fast, while others
  on getting more profit.

  The strategy to use is selected at runtime. See the Manager.Impl.Strategy for more information on this.
  """

  alias Manager.Impl.Strategy, as: StrategyInterface
  alias Shared.Data.{OrderInfo, Product, Strategy}
  alias Shared.Utils.Tuples

  ##########
  # Public #
  ##########

  @spec calculate_price(Product.t(), [OrderInfo.t()], Strategy.id()) :: pos_integer()
  def calculate_price(product, all_orders, strategy_id),
    do:
      all_orders
      |> pre_process_orders()
      |> apply_strategy(strategy_id)
      |> apply_boundaries(product)

  @spec list_strategies :: {:ok, [Strategy.t()]} | {:error, any}
  def list_strategies do
    case :application.get_key(:manager, :modules) do
      {:ok, modules} ->
        modules
        |> Enum.filter(fn module ->
          (module.module_info(:attributes)[:behaviour] || []) |> Enum.member?(StrategyInterface)
        end)
        |> Enum.map(& &1.info())
        |> Enum.sort()
        |> Tuples.to_tagged_tuple()

      error ->
        {:error, error}
    end
  end

  ###########
  # Private #
  ###########

  defp pre_process_orders(all_orders),
    do:
      all_orders
      |> Enum.filter(&valid_order?/1)
      |> Enum.sort(&price_ascending/2)

  @spec valid_order?(OrderInfo.t()) :: boolean
  defp valid_order?(order),
    do: visible?(order) and user_ingame?(order) and can_trade?(order) and sell_order?(order)

  @spec visible?(OrderInfo.t()) :: boolean
  defp visible?(order), do: order.visible == true

  @spec user_ingame?(OrderInfo.t()) :: boolean
  defp user_ingame?(order), do: order.user.status == :ingame

  @spec can_trade?(OrderInfo.t()) :: boolean
  defp can_trade?(order), do: order.user.crossplay == true or order.user.platform == :pc

  @spec sell_order?(OrderInfo.t()) :: boolean
  defp sell_order?(order), do: order.order_type == :sell

  @spec price_ascending(OrderInfo.t(), OrderInfo.t()) :: boolean
  defp price_ascending(order1, order2), do: order1.platinum < order2.platinum

  @spec apply_strategy([OrderInfo.t()], Strategy.id()) :: non_neg_integer()
  defp apply_strategy([], _strategy_id), do: 0

  defp apply_strategy([%OrderInfo{platinum: price}], _strategy_id), do: price

  defp apply_strategy(order_info_from_auction, strategy_id) do
    module = StrategyInterface.id_to_module(strategy_id)
    module.calculate_price(order_info_from_auction)
  end

  @spec apply_boundaries(non_neg_integer(), Product.t()) :: pos_integer()
  defp apply_boundaries(price, %Product{default_price: default}) when price == 0, do: default
  defp apply_boundaries(price, %Product{min_price: min}) when price < min, do: min
  defp apply_boundaries(price, _product) when price > 0, do: price
end
