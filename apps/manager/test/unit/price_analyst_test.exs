defmodule Manager.PriceAnalystTest do
  @moduledoc false

  use ExUnit.Case

  alias Manager.Impl.PriceAnalyst
  alias Shared.Data.{OrderInfo, Product}

  #########
  # Tests #
  #########

  describe "edge cases" do
    test "returns the price of the first element if list size is 1" do
      # Arrange
      order_info = [
        new_order_info(50)
      ]

      product = new_product(1, 1)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, :top_three_average)
      expected = 50

      # Assert
      assert actual == expected
    end

    test "returns default_price with an empty list" do
      # Arrange
      order_info = []
      product = new_product(14, 20)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, :top_three_average)
      expected = 20

      # Assert
      assert actual == expected
    end

    test "returns min_price if the calculated price is lower than min_price" do
      # Arrange
      order_info = [
        new_order_info(10),
        new_order_info(11)
      ]

      product = new_product(14, 16)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, :top_three_average)
      expected = 14

      # Assert
      assert actual == expected
    end
  end

  describe ":top_five_average" do
    test "calculates :top_five_average with a list bigger than 5" do
      # Arrange
      order_info = [
        new_order_info(50),
        new_order_info(55),
        new_order_info(60),
        new_order_info(65),
        new_order_info(55),
        new_order_info(45),
        new_order_info(50_000)
      ]

      product = new_product(1, 1)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, :top_five_average)
      expected = 53

      # Assert
      assert actual == expected
    end

    test "calculates :top_five_average with a list smaller than 5" do
      # Arrange
      order_info = [
        new_order_info(50),
        new_order_info(55),
        new_order_info(50),
        new_order_info(60)
      ]

      product = new_product(1, 1)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, :top_five_average)
      expected = 54

      # Assert
      assert actual == expected
    end
  end

  describe ":top_three_average" do
    test "calculates :top_three_average with a list bigger than 3" do
      # Arrange
      order_info = [
        new_order_info(50),
        new_order_info(55),
        new_order_info(60),
        new_order_info(65),
        new_order_info(55),
        new_order_info(45),
        new_order_info(50_000)
      ]

      product = new_product(1, 1)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, :top_three_average)
      expected = 50

      # Assert
      assert actual == expected
    end

    test "calculates :top_three_average with a list smaller than 3" do
      # Arrange
      order_info = [
        new_order_info(50),
        new_order_info(55)
      ]

      product = new_product(1, 1)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, :top_three_average)
      expected = 53

      # Assert
      assert actual == expected
    end
  end

  describe ":equal_to_lowest" do
    test "returns the price of the lowest element in the list" do
      # Arrange
      order_info = [
        new_order_info(50),
        new_order_info(55),
        new_order_info(60),
        new_order_info(65),
        new_order_info(55),
        new_order_info(45),
        new_order_info(50_000)
      ]

      product = new_product(1, 1)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, :equal_to_lowest)
      expected = 45

      # Assert
      assert actual == expected
    end
  end

  describe ":lowest_minus_one" do
    test "returns the price of the lowest element in the list minus 1" do
      # Arrange
      order_info = [
        new_order_info(50),
        new_order_info(55),
        new_order_info(60),
        new_order_info(65),
        new_order_info(55),
        new_order_info(45),
        new_order_info(50_000)
      ]

      product = new_product(1, 1)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, :lowest_minus_one)
      expected = 44

      # Assert
      assert actual == expected
    end
  end

  ###########
  # Private #
  ###########

  @spec new_order_info(price :: non_neg_integer) :: OrderInfo.t()
  defp new_order_info(price),
    do:
      OrderInfo.new(%{
        "visible" => true,
        "user" => %{"status" => "ingame"},
        "platform" => "pc",
        "order_type" => "sell",
        "platinum" => price
      })

  @spec new_product(min_price :: non_neg_integer, default_price :: non_neg_integer) :: Product.t()
  defp new_product(min_price, default_price),
    do:
      Product.new(%{
        "name" => "a_name",
        "id" => "an_id",
        "min_price" => min_price,
        "default_price" => default_price,
        "quantity" => 1,
        "rank" => 0
      })
end
