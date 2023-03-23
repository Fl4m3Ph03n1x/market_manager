defmodule MarketManager.Store.FileSystemTest do
  @moduledoc false

  use ExUnit.Case

  import Mock

  alias Jason
  alias Shared.Data.{Authorization, PlacedOrder, Product, User}
  alias Store.FileSystem

  describe "list_products/2" do
    test_with_mock "returns list of available products from given syndicate", File,
      cwd: fn -> {:ok, ""} end,
      read: fn _filename ->
        {:ok,
         "{\"red_veil\": [{\"name\": \"Gleaming Blight\",\"id\": \"54a74454e779892d5e5155d5\",\"min_price\": 14,\"default_price\": 16,\"quantity\": 1, \"rank\": 0}]}"}
      end do
      # Arrange
      syndicate = "red_veil"

      # Act
      actual = FileSystem.list_products(syndicate)

      expected =
        {:ok,
         [
           Product.new(%{
             "id" => "54a74454e779892d5e5155d5",
             "name" => "Gleaming Blight",
             "min_price" => 14,
             "default_price" => 16,
             "quantity" => 1,
             "rank" => 0
           })
         ]}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns error if it cannot find directory", File,
      cwd: fn -> {:error, :no_permissions} end do
      # Arrange
      syndicate = "new_loka"

      # Act
      actual = FileSystem.list_products(syndicate)
      expected = {:error, :no_permissions}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
    end

    test_with_mock "returns error if it cannot read file", File,
      cwd: fn -> {:ok, ""} end,
      read: fn _file_name -> {:error, :enoent} end do
      # Arrange
      syndicate = "new_loka"

      # Act
      actual = FileSystem.list_products(syndicate)
      expected = {:error, :enoent}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns error if given syndicate is not found in products file", File,
      cwd: fn -> {:ok, ""} end,
      read: fn _filename -> {:ok, "{}"} end do
      # Arrange
      syndicate = "new_loka"

      # Act
      actual = FileSystem.list_products(syndicate)
      expected = {:error, :syndicate_not_found}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end
  end

  describe "list_orders/2" do
    test_with_mock "returns list of available placed orders from given syndicate", File,
      cwd: fn -> {:ok, ""} end,
      read: fn _file_name ->
        {:ok,
         "{\"new_loka\":[{\"item_name\":\"Abating link\",\"order_id\":\"5ee71a2604d55c0a5cbdc3c2\"},{\"item_name\":\"Vampire leech\",\"order_id\":\"5ee71a2604d55c0a5cbdc3e3\"}]}"}
      end do
      # Arrange
      syndicate = "new_loka"

      # Act
      actual = FileSystem.list_orders(syndicate)

      expected = {
        :ok,
        [
          PlacedOrder.new(%{
            "item_name" => "Abating link",
            "order_id" => "5ee71a2604d55c0a5cbdc3c2"
          }),
          PlacedOrder.new(%{
            "item_name" => "Vampire leech",
            "order_id" => "5ee71a2604d55c0a5cbdc3e3"
          })
        ]
      }

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns error if it cannot find directory", File,
      cwd: fn -> {:error, :no_permissions} end do
      # Arrange
      syndicate = "new_loka"

      # Act
      actual = FileSystem.list_orders(syndicate)
      expected = {:error, :no_permissions}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
    end

    test_with_mock "returns error if it cannot read file", File,
      cwd: fn -> {:ok, ""} end,
      read: fn _file_name -> {:error, :enoent} end do
      # Arrange
      syndicate = "new_loka"

      # Act
      actual = FileSystem.list_orders(syndicate)
      expected = {:error, :enoent}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns error if given syndicate is not found in products file", File,
      cwd: fn -> {:ok, ""} end,
      read: fn _file_name -> {:ok, "{}"} end do
      # Arrange
      syndicate = "new_loka"

      # Act
      actual = FileSystem.list_orders(syndicate)
      expected = {:error, :syndicate_not_found}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end
  end

  describe "save_order/3" do
    test_with_mock "returns :ok if order was saved successfully", File,
      cwd: fn -> {:ok, ""} end,
      read: fn _file_name ->
        {:ok,
         "{\"perrin_sequence\":[{\"item_name\":\"Abating link\",\"order_id\":\"54a74454e779892d5e5155d5\"}]}"}
      end,
      write: fn _file_name, _content -> :ok end do
      # Arrange
      syndicate = "perrin_sequence"

      placed_order =
        PlacedOrder.new(%{
          "item_name" => "Vampire leech",
          "order_id" => "5ee71a2604d55c0a5cbdc3e3"
        })

      expected_saved_data =
        "{\"perrin_sequence\":[{\"item_name\":\"Abating link\",\"order_id\":\"54a74454e779892d5e5155d5\"},{\"item_name\":\"Vampire leech\",\"order_id\":\"5ee71a2604d55c0a5cbdc3e3\"}]}"

      # Act & Assert
      assert FileSystem.save_order(placed_order, syndicate) == :ok
      assert_called(File.cwd())
      assert_called(File.read(:_))
      assert_called(File.write(:_, expected_saved_data))
    end

    test_with_mock "returns error if it fails to find directory", File,
      cwd: fn -> {:error, :no_permissions} end do
      # Arrange
      syndicate = "perrin_sequence"

      placed_order =
        PlacedOrder.new(%{
          "item_name" => "Vampire leech",
          "order_id" => "5ee71a2604d55c0a5cbdc3e3"
        })

      # Act & Assert
      assert FileSystem.save_order(placed_order, syndicate) == {:error, :no_permissions}
      assert_called(File.cwd())
    end

    test_with_mock "returns error if it failed to read file", File,
      cwd: fn -> {:ok, ""} end,
      read: fn _file_name -> {:error, :enoent} end do
      # Arrange
      syndicate = "perrin_sequence"

      placed_order =
        PlacedOrder.new(%{
          "item_name" => "Vampire leech",
          "order_id" => "5ee71a2604d55c0a5cbdc3e3"
        })

      # Act & Assert
      assert FileSystem.save_order(placed_order, syndicate) == {:error, :enoent}
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns error if it failed to save order", File,
      cwd: fn -> {:ok, ""} end,
      read: fn _file_name ->
        {:ok,
         "{\"perrin_sequence\":[{\"item_name\":\"Abating link\",\"order_id\":\"54a74454e779892d5e5155d5\"}]}"}
      end,
      write: fn _file_name, _content -> {:error, :enoent} end do
      # Arrange
      syndicate = "perrin_sequence"

      placed_order =
        PlacedOrder.new(%{
          "item_name" => "Vampire leech",
          "order_id" => "5ee71a2604d55c0a5cbdc3e3"
        })

      # Act & Assert
      assert FileSystem.save_order(placed_order, syndicate) == {:error, :enoent}
      assert_called(File.cwd())
      assert_called(File.read(:_))
      assert_called(File.write(:_, :_))
    end
  end

  describe "delete_order/3" do
    test_with_mock "returns :ok if order was deleted successfully", File,
      cwd: fn -> {:ok, ""} end,
      read: fn _file_name ->
        {:ok,
         "{\"perrin_sequence\":[{\"item_name\":\"Abating link\",\"order_id\":\"54a74454e779892d5e5155d5\"}]}"}
      end,
      write: fn _file_name, _content -> :ok end do
      # Arrange
      syndicate = "perrin_sequence"

      placed_order =
        PlacedOrder.new(%{
          "item_name" => "Abating link",
          "order_id" => "54a74454e779892d5e5155d5"
        })

      # Act & Assert
      assert FileSystem.delete_order(placed_order, syndicate) == :ok
      assert_called(File.cwd())
      assert_called(File.read(:_))
      assert_called(File.write(:_, "{\"perrin_sequence\":[]}"))
    end

    test_with_mock "returns error if it fails to find directory", File,
      cwd: fn -> {:error, :no_permissions} end do
      # Arrange
      syndicate = "perrin_sequence"

      placed_order =
        PlacedOrder.new(%{
          "item_name" => "Abating link",
          "order_id" => "54a74454e779892d5e5155d5"
        })

      # Act & Assert
      assert FileSystem.delete_order(placed_order, syndicate) == {:error, :no_permissions}
      assert_called(File.cwd())
    end

    test_with_mock "returns error if it fails to read file", File,
      cwd: fn -> {:ok, ""} end,
      read: fn _file_name -> {:error, :enoent} end do
      # Arrange
      syndicate = "perrin_sequence"

      placed_order =
        PlacedOrder.new(%{
          "item_name" => "Abating link",
          "order_id" => "54a74454e779892d5e5155d5"
        })

      # Act & Assert
      assert FileSystem.delete_order(placed_order, syndicate) == {:error, :enoent}
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns error if it failed to save deleted order", File,
      cwd: fn -> {:ok, ""} end,
      read: fn _file_name ->
        {:ok,
         "{\"perrin_sequence\":[{\"item_name\":\"Abating link\",\"order_id\":\"54a74454e779892d5e5155d5\"}]}"}
      end,
      write: fn _file_name, _content -> {:error, :enoent} end do
      # Arrange
      syndicate = "perrin_sequence"

      placed_order =
        PlacedOrder.new(%{
          "item_name" => "Abating link",
          "order_id" => "54a74454e779892d5e5155d5"
        })

      # Act & Assert
      assert FileSystem.delete_order(placed_order, syndicate) == {:error, :enoent}
      assert_called(File.cwd())
      assert_called(File.read(:_))
      assert_called(File.write(:_, "{\"perrin_sequence\":[]}"))
    end
  end

  describe "save_login_data/3" do
    test_with_mock "returns :ok if cwd and write were successful", File,
      write: fn _file_name, _content -> :ok end,
      cwd: fn -> {:ok, "home/user"} end do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      # Act
      actual = FileSystem.save_login_data(auth, user)
      expected = :ok
      expected_content = Jason.encode!(%{authorization: auth, user: user})

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.write(:_, expected_content))
    end

    test_with_mock "returns error if cwd succeeded but write to file failed", File,
      write: fn _file_name, _content -> {:error, :enoent} end,
      cwd: fn -> {:ok, "home/user"} end do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      # Act
      actual = FileSystem.save_login_data(auth, user)
      expected = {:error, :enoent}
      expected_content = Jason.encode!(%{authorization: auth, user: user})

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.write(:_, expected_content))
    end

    test_with_mock "returns error if cwd failed", File, cwd: fn -> {:error, :no_permissions} end do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      # Act
      actual = FileSystem.save_login_data(auth, user)
      expected = {:error, :no_permissions}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
    end
  end

  describe "get_login_data/1" do
    test_with_mock "returns login_data if cwd and read succeeded", File,
      cwd: fn -> {:ok, "home/user"} end,
      read: fn _file_name ->
        {:ok,
         "{\"authorization\":{\"cookie\":\"a_cookie\",\"token\":\"a_token\"},\"user\":{\"ingame_name\":\"fl4m3\",\"patreon?\":false}}"}
      end do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, {auth, user}}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if cwd and read succeeded but authorization cookie is null",
                   File,
                   cwd: fn -> {:ok, "home/user"} end,
                   read: fn _file_name ->
                     {:ok,
                      "{\"authorization\":{\"cookie\": null,\"token\":\"a_token\"},\"user\":{\"ingame_name\":\"fl4m3\",\"patreon?\":false}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if cwd and read succeeded but authorization token is null",
                   File,
                   cwd: fn -> {:ok, "home/user"} end,
                   read: fn _file_name ->
                     {:ok,
                      "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": null},\"user\":{\"ingame_name\":\"fl4m3\",\"patreon?\":false}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if cwd and read succeeded but user ingame_name is null",
                   File,
                   cwd: fn -> {:ok, "home/user"} end,
                   read: fn _file_name ->
                     {:ok,
                      "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": \"a_token\"},\"user\":{\"ingame_name\": null,\"patreon?\":false}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if cwd and read succeeded but user patreon? is null",
                   File,
                   cwd: fn -> {:ok, "home/user"} end,
                   read: fn _file_name ->
                     {:ok,
                      "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": \"a_token\"},\"user\":{\"ingame_name\": \"fl4m3\",\"patreon?\": null}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if cwd and read succeeded but authorization is missing",
                   File,
                   cwd: fn -> {:ok, "home/user"} end,
                   read: fn _file_name ->
                     {:ok, "{\"user\":{\"ingame_name\": \"fl4m3\",\"patreon?\": false}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if cwd and read succeeded but user is missing",
                   File,
                   cwd: fn -> {:ok, "home/user"} end,
                   read: fn _file_name ->
                     {:ok,
                      "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": \"a_token\"}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns error if cwd fails", File, cwd: fn -> {:error, :no_permissions} end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:error, :no_permissions}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
    end
  end

  describe "delete_login_data/3" do
    test_with_mock "returns :ok if cwd and write were successful", File,
      write: fn _file_name, _content -> :ok end,
      cwd: fn -> {:ok, "home/user"} end do
      # Arrange & Act
      actual = FileSystem.delete_login_data()
      expected = :ok

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.write(:_, "{}"))
    end

    test_with_mock "returns error if cwd succeeded but write to file failed", File,
      write: fn _file_name, _content -> {:error, :enoent} end,
      cwd: fn -> {:ok, "home/user"} end do
      # Arrange & Act
      actual = FileSystem.delete_login_data()
      expected = {:error, :enoent}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.write(:_, "{}"))
    end

    test_with_mock "returns error if cwd failed", File, cwd: fn -> {:error, :no_permissions} end do
      # Arrange & Act
      actual = FileSystem.delete_login_data()
      expected = {:error, :no_permissions}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
    end
  end
end
