defmodule Manager.PriceAnalystTest do
  @moduledoc false

  use ExUnit.Case

  alias Helpers
  alias Manager.Impl.PriceAnalyst

  #########
  # Tests #
  #########

  describe "edge cases" do
    test "returns the price of the first element if list size is 1" do
      # Arrange
      order_info = [
        Helpers.create_order_info(platinum: 50)
      ]

      product = Helpers.create_product(min_price: 1, default_price: 1)
      strategy = Helpers.strategy(:top_three_average)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, strategy)
      expected = 50

      # Assert
      assert actual == expected
    end

    test "returns default_price with an empty list" do
      # Arrange
      order_info = []
      product = Helpers.create_product(min_price: 14, default_price: 20)
      strategy = Helpers.strategy(:top_three_average)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, strategy)
      expected = 20

      # Assert
      assert actual == expected
    end

    test "returns min_price if the calculated price is lower than min_price" do
      # Arrange
      order_info = [
        Helpers.create_order_info(platinum: 10),
        Helpers.create_order_info(platinum: 11)
      ]

      product = Helpers.create_product(min_price: 14, default_price: 16)
      strategy = Helpers.strategy(:top_three_average)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, strategy)
      expected = 14

      # Assert
      assert actual == expected
    end
  end

  describe ":top_five_average" do
    test "calculates :top_five_average with a list bigger than 5" do
      # Arrange
      order_info = [
        Helpers.create_order_info(platinum: 50),
        Helpers.create_order_info(platinum: 55),
        Helpers.create_order_info(platinum: 60),
        Helpers.create_order_info(platinum: 65),
        Helpers.create_order_info(platinum: 55),
        Helpers.create_order_info(platinum: 45),
        Helpers.create_order_info(platinum: 50_000)
      ]

      product = Helpers.create_product(min_price: 1, default_price: 1)
      strategy = Helpers.strategy(:top_five_average)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, strategy)
      expected = 53

      # Assert
      assert actual == expected
    end

    test "calculates :top_five_average with a list smaller than 5" do
      # Arrange
      order_info = [
        Helpers.create_order_info(platinum: 50),
        Helpers.create_order_info(platinum: 55),
        Helpers.create_order_info(platinum: 50),
        Helpers.create_order_info(platinum: 60)
      ]

      product = Helpers.create_product(min_price: 1, default_price: 1)
      strategy = Helpers.strategy(:top_five_average)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, strategy)
      expected = 54

      # Assert
      assert actual == expected
    end
  end

  describe ":top_three_average" do
    test "calculates :top_three_average with a list bigger than 3" do
      # Arrange
      order_info = [
        Helpers.create_order_info(platinum: 50),
        Helpers.create_order_info(platinum: 55),
        Helpers.create_order_info(platinum: 60),
        Helpers.create_order_info(platinum: 65),
        Helpers.create_order_info(platinum: 55),
        Helpers.create_order_info(platinum: 45),
        Helpers.create_order_info(platinum: 50_000)
      ]

      product = Helpers.create_product(min_price: 1, default_price: 1)
      strategy = Helpers.strategy(:top_three_average)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, strategy)
      expected = 50

      # Assert
      assert actual == expected
    end

    test "calculates :top_three_average with a list smaller than 3" do
      # Arrange
      order_info = [
        Helpers.create_order_info(platinum: 50),
        Helpers.create_order_info(platinum: 55)
      ]

      product = Helpers.create_product(min_price: 1, default_price: 1)
      strategy = Helpers.strategy(:top_three_average)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, strategy)
      expected = 53

      # Assert
      assert actual == expected
    end
  end

  describe ":equal_to_lowest" do
    test "returns the price of the lowest element in the list" do
      # Arrange
      order_info = [
        Helpers.create_order_info(platinum: 50),
        Helpers.create_order_info(platinum: 55),
        Helpers.create_order_info(platinum: 60),
        Helpers.create_order_info(platinum: 65),
        Helpers.create_order_info(platinum: 55),
        Helpers.create_order_info(platinum: 45),
        Helpers.create_order_info(platinum: 50_000)
      ]

      product = Helpers.create_product(min_price: 1, default_price: 1)
      strategy = Helpers.strategy(:equal_to_lowest)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, strategy)
      expected = 45

      # Assert
      assert actual == expected
    end
  end

  describe ":lowest_minus_one" do
    test "returns the price of the lowest element in the list minus 1" do
      # Arrange
      order_info = [
        Helpers.create_order_info(platinum: 50),
        Helpers.create_order_info(platinum: 55),
        Helpers.create_order_info(platinum: 60),
        Helpers.create_order_info(platinum: 65),
        Helpers.create_order_info(platinum: 55),
        Helpers.create_order_info(platinum: 45),
        Helpers.create_order_info(platinum: 50_000)
      ]

      product = Helpers.create_product(min_price: 1, default_price: 1)
      strategy = Helpers.strategy(:lowest_minus_one)

      # Act
      actual = PriceAnalyst.calculate_price(product, order_info, strategy)
      expected = 44

      # Assert
      assert actual == expected
    end
  end
end
