defmodule MarketManager.Store.FileSystemTest do
  @moduledoc false

  use ExUnit.Case

  import Mock

  alias Jason
  alias Shared.Data.{Authorization, PlacedOrder, Product, Syndicate, User}
  alias Store.FileSystem

  setup do
    %{
      file_io: File,
      paths: [
        current_orders: ["current_orders.json"],
        products: ["products.json"],
        syndicates: ["syndicates.json"],
        setup: ["setup.json"]
      ],
      env: :test
    }
  end

  describe "list_products/2" do
    test_with_mock "returns list of available products from given syndicate",
                   %{paths: paths} = deps,
                   File,
                   [],
                   read: fn _file_name ->
                     {:ok,
                      "[{\"name\": \"Gleaming Blight\",\"id\": \"54a74454e779892d5e5155d5\",\"min_price\": 14,\"default_price\": 16,\"quantity\": 1, \"rank\": 0}]"}
                   end do
      # Arrange
      syndicate =
        Syndicate.new(name: "Red Veil", id: :red_veil, catalog: ["54a74454e779892d5e5155d5"])

      # Act
      actual = FileSystem.list_products(syndicate, deps)

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

      expected_products_path = Path.join(paths[:products])

      # Assert
      assert actual == expected
      assert_called(File.read(expected_products_path))
    end

    test_with_mock "returns error if it cannot read file", %{paths: paths} = deps, File, [],
      read: fn _file_name -> {:error, :enoent} end do
      # Arrange
      syndicate = Syndicate.new(name: "New Loka", id: :new_loka, catalog: [])

      # Act
      actual = FileSystem.list_products(syndicate, deps)
      expected = {:error, :enoent}
      expected_products_path = Path.join(paths[:products])

      # Assert
      assert actual == expected
      assert_called(File.read(expected_products_path))
    end
  end

  describe "list_orders/2" do
    test_with_mock "returns list of available placed orders from given syndicate",
                   %{paths: paths} = deps,
                   File,
                   [],
                   read: fn _file_name ->
                     {:ok,
                      "{\"new_loka\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"5ee71a2604d55c0a5cbdc3c2\"},{\"item_id\":\"Vampire leech\",\"order_id\":\"5ee71a2604d55c0a5cbdc3e3\"}]}"}
                   end do
      # Arrange
      syndicate = Syndicate.new(name: "New Loka", id: :new_loka, catalog: [])

      # Act
      actual = FileSystem.list_orders(syndicate, deps)

      expected = {
        :ok,
        [
          PlacedOrder.new(%{
            "item_id" => "54e644ffe779897594fa68d2",
            "order_id" => "5ee71a2604d55c0a5cbdc3c2"
          }),
          PlacedOrder.new(%{
            "item_id" => "Vampire leech",
            "order_id" => "5ee71a2604d55c0a5cbdc3e3"
          })
        ]
      }

      expected_path = Path.join(paths[:current_orders])

      # Assert
      assert actual == expected
      assert_called(File.read(expected_path))
    end

    test_with_mock "returns empty if syndicate is not found", %{paths: paths} = deps, File, [],
      read: fn _file_name ->
        {:ok,
         "{\"red_veil\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"5ee71a2604d55c0a5cbdc3c2\"}]}"}
      end do
      # Arrange
      syndicate = Syndicate.new(name: "New Loka", id: :new_loka, catalog: [])

      # Act
      actual = FileSystem.list_orders(syndicate, deps)
      expected = {:ok, []}
      expected_path = Path.join(paths[:current_orders])

      # Assert
      assert actual == expected
      assert_called(File.read(expected_path))
    end

    test_with_mock "returns error if it cannot read file", %{paths: paths} = deps, File, [],
      read: fn _file_name -> {:error, :enoent} end do
      # Arrange
      syndicate = Syndicate.new(name: "New Loka", id: :new_loka, catalog: [])

      # Act
      actual = FileSystem.list_orders(syndicate, deps)
      expected = {:error, :enoent}
      expected_path = Path.join(paths[:current_orders])

      # Assert
      assert actual == expected
      assert_called(File.read(expected_path))
    end
  end

  describe "save_order/3" do
    test_with_mock "returns :ok if order was saved successfully",
                   %{paths: paths} = deps,
                   File,
                   [],
                   read: fn _file_name ->
                     {:ok,
                      "{\"perrin_sequence\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"54a74454e779892d5e5155d5\"}]}"}
                   end,
                   write: fn _file_name, _content -> :ok end do
      # Arrange
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: [])

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "Vampire leech",
          "order_id" => "5ee71a2604d55c0a5cbdc3e3"
        })

      expected_saved_data =
        "{\"perrin_sequence\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"54a74454e779892d5e5155d5\"},{\"item_id\":\"Vampire leech\",\"order_id\":\"5ee71a2604d55c0a5cbdc3e3\"}]}"

      expected_path = Path.join(paths[:current_orders])

      # Act & Assert
      assert FileSystem.save_order(placed_order, syndicate, deps) == :ok
      assert_called(File.read(expected_path))
      assert_called(File.write(expected_path, expected_saved_data))
    end

    test_with_mock "returns error if it failed to read file", %{paths: paths} = deps, File, [],
      read: fn _file_name -> {:error, :enoent} end do
      # Arrange
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: [])

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "Vampire leech",
          "order_id" => "5ee71a2604d55c0a5cbdc3e3"
        })

      expected_path = Path.join(paths[:current_orders])

      # Act & Assert
      assert FileSystem.save_order(placed_order, syndicate, deps) == {:error, :enoent}
      assert_called(File.read(expected_path))
    end

    test_with_mock "returns error if it failed to save order", %{paths: paths} = deps, File, [],
      read: fn _file_name ->
        {:ok,
         "{\"perrin_sequence\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"54a74454e779892d5e5155d5\"}]}"}
      end,
      write: fn _file_name, _content -> {:error, :enoent} end do
      # Arrange
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: [])

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "Vampire leech",
          "order_id" => "5ee71a2604d55c0a5cbdc3e3"
        })

      expected_path = Path.join(paths[:current_orders])

      # Act & Assert
      assert FileSystem.save_order(placed_order, syndicate, deps) == {:error, :enoent}
      assert_called(File.read(expected_path))
      assert_called(File.write(expected_path, :_))
    end
  end

  describe "delete_order/3" do
    test_with_mock "returns :ok if order was deleted successfully",
                   %{paths: paths} = deps,
                   File,
                   [],
                   read: fn _file_name ->
                     {:ok,
                      "{\"perrin_sequence\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"54a74454e779892d5e5155d5\"}]}"}
                   end,
                   write: fn _file_name, _content -> :ok end do
      # Arrange
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: [])

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "54e644ffe779897594fa68d2",
          "order_id" => "54a74454e779892d5e5155d5"
        })

      expected_orders_path = Path.join(paths[:current_orders])

      # Act & Assert
      assert FileSystem.delete_order(placed_order, syndicate, deps) == :ok
      assert_called(File.read(expected_orders_path))
      assert_called(File.write(expected_orders_path, "{\"perrin_sequence\":[]}"))
    end

    test_with_mock "returns error if it fails to read file", %{paths: paths} = deps, File, [],
      read: fn _file_name -> {:error, :enoent} end do
      # Arrange
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: [])

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "54e644ffe779897594fa68d2",
          "order_id" => "54a74454e779892d5e5155d5"
        })

      expected_orders_path = Path.join(paths[:current_orders])

      # Act & Assert
      assert FileSystem.delete_order(placed_order, syndicate, deps) == {:error, :enoent}
      assert_called(File.read(expected_orders_path))
    end

    test_with_mock "returns error if it failed to save deleted order",
                   %{paths: paths} = deps,
                   File,
                   [],
                   read: fn _file_name ->
                     {:ok,
                      "{\"perrin_sequence\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"54a74454e779892d5e5155d5\"}]}"}
                   end,
                   write: fn _file_name, _content -> {:error, :enoent} end do
      # Arrange
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: [])

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "54e644ffe779897594fa68d2",
          "order_id" => "54a74454e779892d5e5155d5"
        })

      expected_orders_path = Path.join(paths[:current_orders])
      # Act & Assert
      assert FileSystem.delete_order(placed_order, syndicate, deps) == {:error, :enoent}
      assert_called(File.read(expected_orders_path))
      assert_called(File.write(expected_orders_path, "{\"perrin_sequence\":[]}"))
    end
  end

  describe "save_login_data/3" do
    test_with_mock "returns :ok if write was successful", File,
      write: fn _file_name, _content -> :ok end do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      # Act
      actual = FileSystem.save_login_data(auth, user)
      expected = :ok
      expected_content = Jason.encode!(%{authorization: auth, user: user})

      # Assert
      assert actual == expected
      assert_called(File.write(:_, expected_content))
    end

    test_with_mock "returns error if write to file failed", File,
      write: fn _file_name, _content -> {:error, :enoent} end do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      # Act
      actual = FileSystem.save_login_data(auth, user)
      expected = {:error, :enoent}
      expected_content = Jason.encode!(%{authorization: auth, user: user})

      # Assert
      assert actual == expected
      assert_called(File.write(:_, expected_content))
    end
  end

  describe "get_login_data/1" do
    test_with_mock "returns login_data if read succeeded", File,
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
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if read succeeded but authorization cookie is null",
                   File,
                   read: fn _file_name ->
                     {:ok,
                      "{\"authorization\":{\"cookie\": null,\"token\":\"a_token\"},\"user\":{\"ingame_name\":\"fl4m3\",\"patreon?\":false}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if read succeeded but authorization token is null",
                   File,
                   read: fn _file_name ->
                     {:ok,
                      "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": null},\"user\":{\"ingame_name\":\"fl4m3\",\"patreon?\":false}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if read succeeded but user ingame_name is null",
                   File,
                   read: fn _file_name ->
                     {:ok,
                      "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": \"a_token\"},\"user\":{\"ingame_name\": null,\"patreon?\":false}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if read succeeded but user patreon? is null",
                   File,
                   read: fn _file_name ->
                     {:ok,
                      "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": \"a_token\"},\"user\":{\"ingame_name\": \"fl4m3\",\"patreon?\": null}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if read succeeded but authorization is missing",
                   File,
                   read: fn _file_name ->
                     {:ok, "{\"user\":{\"ingame_name\": \"fl4m3\",\"patreon?\": false}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if read succeeded but user is missing",
                   File,
                   read: fn _file_name ->
                     {:ok,
                      "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": \"a_token\"}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.read(:_))
    end
  end

  describe "delete_login_data/3" do
    test_with_mock "returns :ok if write was successful", File,
      write: fn _file_name, _content -> :ok end do
      # Arrange & Act
      actual = FileSystem.delete_login_data()
      expected = :ok

      # Assert
      assert actual == expected
      assert_called(File.write(:_, "{}"))
    end

    test_with_mock "returns error if write to file failed", File,
      write: fn _file_name, _content -> {:error, :enoent} end do
      # Arrange & Act
      actual = FileSystem.delete_login_data()
      expected = {:error, :enoent}

      # Assert
      assert actual == expected
      assert_called(File.write(:_, "{}"))
    end
  end

  describe "list_syndicates/1" do
    test_with_mock "returns the list of all known syndicates", %{paths: paths} = deps, File, [],
      read: fn _filename ->
        {:ok,
         "[{\"id\":\"red_veil\",\"name\":\"Red Veil\",\"catalog\":[]},{\"id\":\"perrin_sequence\",\"name\":\"Perrin Sequence\",\"catalog\":[]}]"}
      end do
      # Act
      actual = FileSystem.list_syndicates(deps)

      expected =
        {:ok,
         [
           %Syndicate{name: "Red Veil", id: :red_veil, catalog: []},
           %Syndicate{name: "Perrin Sequence", id: :perrin_sequence, catalog: []}
         ]}
         expected_path = Path.join(paths[:syndicates])

      # Assert
      assert actual == expected
      assert_called(File.read(expected_path))
    end

    test_with_mock "returns error if it cannot read file", %{paths: paths} = deps, File, [],
      read: fn _file_name -> {:error, :enoent} end do
      # Act
      actual = FileSystem.list_syndicates(deps)
      expected = {:error, :enoent}
      expected_path = Path.join(paths[:syndicates])

      # Assert
      assert actual == expected
      assert_called(File.read(expected_path))
    end
  end

  describe "list_active_syndicates/1" do
    test_with_mock "returns the list of all active syndicates", %{paths: paths} = deps, File, [],
      read: fn
        "current_orders.json" ->
          {:ok,
           "{\"new_loka\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"5ee71a2604d55c0a5cbdc3c2\"},{\"item_id\":\"Vampire leech\",\"order_id\":\"5ee71a2604d55c0a5cbdc3e3\"}]}"}

        "syndicates.json" ->
          {:ok,
           "[{\"id\":\"new_loka\",\"name\":\"New Loka\",\"catalog\":[]},{\"id\":\"perrin_sequence\",\"name\":\"Perrin Sequence\",\"catalog\":[]}]"}
      end do
      # Act
      actual = FileSystem.list_active_syndicates(deps)

      expected =
        {:ok, [%Syndicate{name: "New Loka", id: :new_loka, catalog: []}]}

      current_orders_path = Path.join(paths[:current_orders])
      syndicates_path = Path.join(paths[:syndicates])

      # Assert
      assert actual == expected
      assert_called(File.read(current_orders_path))
      assert_called(File.read(syndicates_path))
    end

    test_with_mock "returns the error if it fails to read current_orders.json",
                   %{paths: paths} = deps,
                   File,
                   [],
                   read: fn
                     "current_orders.json" ->
                       {:error, :enoent}

                     "syndicates.json" ->
                       {:ok,
                        "[{\"id\":\"new_loka\",\"name\":\"New Loka\",\"catalog\":[]},{\"id\":\"perrin_sequence\",\"name\":\"Perrin Sequence\",\"catalog\":[]}]"}
                   end do
      # Act
      actual = FileSystem.list_active_syndicates(deps)
      expected = {:error, :enoent}
      current_orders_path = Path.join(paths[:current_orders])
      syndicates_path = Path.join(paths[:syndicates])

      # Assert
      assert actual == expected
      assert_called(File.read(current_orders_path))
      assert_not_called(File.read(syndicates_path))
    end

    test_with_mock "returns the error if it fails to read syndicates.json",
                   %{paths: paths} = deps,
                   File,
                   [],
                   read: fn
                     "current_orders.json" ->
                       {:ok,
                        "{\"new_loka\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"5ee71a2604d55c0a5cbdc3c2\"},{\"item_id\":\"Vampire leech\",\"order_id\":\"5ee71a2604d55c0a5cbdc3e3\"}]}"}

                     "syndicates.json" ->
                       {:error, :enoent}
                   end do
      # Act
      actual = FileSystem.list_active_syndicates(deps)
      expected = {:error, :enoent}
      current_orders_path = Path.join(paths[:current_orders])
      syndicates_path = Path.join(paths[:syndicates])

      # Assert
      assert actual == expected
      assert_called(File.read(current_orders_path))
      assert_called(File.read(syndicates_path))
    end
  end
end
