defmodule MarketManager.PriceAnalystTest do
  use ExUnit.Case

  alias MarketManager.PriceAnalyst

  describe ":top_five_average" do
    test "calculates :top_five_average with a list bigger than 5" do
      # Arrange
      order_info = [
        %{"platinum" => 50},
        %{"platinum" => 55},
        %{"platinum" => 60},
        %{"platinum" => 65},
        %{"platinum" => 55},
        %{"platinum" => 45},
        %{ "platinum" => 50000}
      ]

      # Act
      actual = PriceAnalyst.calculate_price(order_info, :top_five_average)
      expected = [53]

      # Assert
      assert actual == expected
    end

    test "calculates :top_five_average with a list smaller than 5" do
      # Arrange
      order_info = [
        %{"platinum" => 50},
        %{"platinum" => 55},
        %{"platinum" => 50},
        %{"platinum" => 60}
      ]

      # Act
      actual = PriceAnalyst.calculate_price(order_info, :top_five_average)
      expected = [54]

      # Assert
      assert actual == expected
    end

    test "returns the price of the first element if list size is 1" do
      # Arrange
      order_info = [
        %{"platinum" => 50}
      ]

      # Act
      actual = PriceAnalyst.calculate_price(order_info, :top_five_average)
      expected = [50]

      # Assert
      assert actual == expected
    end

    test "returns 0 with an empty list" do
      # Arrange
      order_info = []

      # Act
      actual = PriceAnalyst.calculate_price(order_info, :top_five_average)
      expected = [0]

      # Assert
      assert actual == expected
    end
  end


end
