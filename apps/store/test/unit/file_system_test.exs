defmodule MarketManager.Store.FileSystemTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.{Authorization, User}
  alias Store.FileSystem

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
      expected = {:error, :syndicate_not_found}

      # Assert
      assert actual == expected
    end
  end

  describe "list_orders/2" do
    test "returns list of available orders from given syndicate" do
      # Arrange
      syndicate = "new_loka"

      deps = [
        read_fn: fn _file_name ->
          {:ok, "{\"new_loka\":[\"5ee71a2604d55c0a5cbdc3c2\",\"5ee71a2604d55c0a5cbdc3e3\"]}"}
        end
      ]

      # Act
      actual = FileSystem.list_orders(syndicate, deps)

      expected = {
        :ok,
        ["5ee71a2604d55c0a5cbdc3c2", "5ee71a2604d55c0a5cbdc3e3"]
      }

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
      actual = FileSystem.list_orders(syndicate, deps)
      expected = {:error, :syndicate_not_found}

      # Assert
      assert actual == expected
    end
  end

  describe "save_order/3" do
    test "returns order_id if order was saved successfully" do
      # Arrange
      syndicate = "perrin_sequence"
      order_id = "54a74454e779892d5e5155d5"

      deps = [
        read_fn: fn _file_name ->
          {:ok, "{\"perrin_sequence\":[\"5ee71a2604d55c0a5cbdc3c2\"]}"}
        end,
        write_fn: fn _file_name, _content -> :ok end
      ]

      # Act
      actual = FileSystem.save_order(order_id, syndicate, deps)
      expected = {:ok, order_id}

      # Assert
      assert actual == expected
    end

    test "returns error if it failed to save order" do
      # Arrange
      syndicate = "perrin_sequence"
      order_id = "54a74454e779892d5e5155d5"

      deps = [
        read_fn: fn _file_name -> {:error, :enoent} end
      ]

      # Act
      actual = FileSystem.save_order(order_id, syndicate, deps)
      expected = {:error, :enoent}

      # Assert
      assert actual == expected
    end
  end

  describe "delete_order/3" do
    test "returns order_id if order was deleted successfully" do
      # Arrange
      syndicate = "perrin_sequence"
      order_id = "54a74454e779892d5e5155d5"

      deps = [
        read_fn: fn _file_name ->
          {:ok, "{\"perrin_sequence\":[\"5ee71a2604d55c0a5cbdc3c2\"]}"}
        end,
        write_fn: fn _file_name, _content -> :ok end
      ]

      # Act
      actual = FileSystem.delete_order(order_id, syndicate, deps)
      expected = {:ok, order_id}

      # Assert
      assert actual == expected
    end

    test "returns error if it failed to save order" do
      # Arrange
      syndicate = "perrin_sequence"
      order_id = "54a74454e779892d5e5155d5"

      deps = [
        read_fn: fn _file_name ->
          {:ok, "{\"perrin_sequence\":[\"5ee71a2604d55c0a5cbdc3c2\"]}"}
        end,
        write_fn: fn _file_name, _content -> {:error, :no_persmission} end
      ]

      # Act
      actual = FileSystem.delete_order(order_id, syndicate, deps)
      expected = {:error, :no_persmission}

      # Assert
      assert actual == expected
    end
  end

  describe "save_login_data/3" do
    test "returns :ok if login data was saved successfully" do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      deps = [
        write_fn: fn _file_name, _content -> :ok end,
        current_working_directory: fn -> {:ok, "home/user"} end
      ]

      # Act
      actual = FileSystem.save_login_data(auth, user, deps)
      expected = :ok

      # Assert
      assert actual == expected
    end

    test "returns error if saving to file fails" do
      # Arrange
      login_info = %{"token" => "a_token", "cookie" => "a_cookie"}

      deps = [
        write_fn: fn _file_name, _content -> {:error, :enoent} end
      ]

      # Act
      actual = FileSystem.save_credentials(login_info, deps)
      expected = {:error, :enoent}

      # Assert
      assert actual == expected
    end
  end

  # describe "get_creadentials/0" do
  #   test "returns login_info" do
  #     # Arrange
  #     login_info = %{"token" => "a_token", "cookie" => "a_cookie"}

  #     deps = [
  #       read_fn: fn _file_name -> {:ok, '{"cookie":"a_cookie","token":"a_token"}'} end
  #     ]

  #     # Act
  #     actual = FileSystem.get_credentials(deps)
  #     expected = {:ok, login_info}

  #     # Assert
  #     assert actual == expected
  #   end

  #   test "returns error if reading file fails" do
  #     # Arrange
  #     deps = [
  #       read_fn: fn _file_name -> {:error, :enoent} end
  #     ]

  #     # Act
  #     actual = FileSystem.get_credentials(deps)
  #     expected = {:error, :enoent}

  #     # Assert
  #     assert actual == expected
  #   end
  # end
end
