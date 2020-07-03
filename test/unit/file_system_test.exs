defmodule FileSystemTest do
  use ExUnit.Case

  alias MarketManager.Store.FileSystem

  describe "list_products/2" do
    test "returns list of available products from given syndicate" do
      # Arrange
      syndicate = "red_veil"

      deps = [
        read_fn: fn _file_name ->
          {:ok,
           "{\"red_veil\": [{\"name\": \"Gleaming Blight\",\"id\": \"54a74454e779892d5e5155d5\",\"price\": 14}]}"}
        end
      ]

      # Act
      actual = FileSystem.list_products(syndicate, deps)

      expected =
        {:ok,
         [
           %{
             "id" => "54a74454e779892d5e5155d5",
             "name" => "Gleaming Blight",
             "price" => 14
           }
         ]}

      # Assert
      assert actual == expected
    end

    test "returns error if given syndicate is not found in products file" do
      # Arrange
      syndicate = "new_loka"

      deps = [
        read_fn: fn _file_name -> {:ok, "{}"} end
      ]

      # Act
      actual = FileSystem.list_products(syndicate, deps)
      expected = {:error, :syndicate_not_found, syndicate}

      # Assert
      assert actual == expected
    end
  end

  # describe "list_orders/2" do
  # end

  # describe "save_order/3" do
  # end

  # describe "delete_order/3" do
  # end
end
