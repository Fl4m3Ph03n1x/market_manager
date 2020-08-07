defmodule Manager.PriceAnalystTest do
  use ExUnit.Case

  alias Manager.PriceAnalyst

  #########
  # Tests #
  #########

  describe "edge cases" do
    test "returns the price of the first element if list size is 1" do
      # Arrange
      order_info = [
        new_order_info(50)
      ]

      # Act
      actual = PriceAnalyst.calculate_price(order_info, :top_three_average)
      expected = 50

      # Assert
      assert actual == expected
    end

    test "returns 0 with an empty list" do
      # Arrange
      order_info = []

      # Act
      actual = PriceAnalyst.calculate_price(order_info, :top_three_average)
      expected = 0

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

      # Act
      actual = PriceAnalyst.calculate_price(order_info, :top_five_average)
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

      # Act
      actual = PriceAnalyst.calculate_price(order_info, :top_five_average)
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

      # Act
      actual = PriceAnalyst.calculate_price(order_info, :top_three_average)
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

      # Act
      actual = PriceAnalyst.calculate_price(order_info, :top_three_average)
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

      # Act
      actual = PriceAnalyst.calculate_price(order_info, :equal_to_lowest)
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

      # Act
      actual = PriceAnalyst.calculate_price(order_info, :lowest_minus_one)
      expected = 44

      # Assert
      assert actual == expected
    end
  end

  ###########
  # Private #
  ###########

  defp new_order_info(price), do:
    %{
      "visible" => true,
      "user" => %{"status" => "ingame"},
      "platform" => "pc",
      "order_type"=> "sell",
      "platinum" => price
    }

end
