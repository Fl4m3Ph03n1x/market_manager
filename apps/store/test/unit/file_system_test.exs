defmodule MarketManager.Store.FileSystemTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Jason
  alias Shared.Data.{Authorization, PlacedOrder, Product, Syndicate, User}
  alias Store.FileSystem

  setup do
    %{
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
    test "returns list of available products from given syndicate", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:products])

        {:ok,
         "[{\"name\": \"Gleaming Blight\",\"id\": \"54a74454e779892d5e5155d5\",\"min_price\": 14,\"default_price\": 16,\"quantity\": 1, \"rank\": 0}]"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

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

      # Assert
      assert actual == expected
    end

    test "returns error if it cannot read file", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:products])
        {:error, :enoent}
      end

      deps = Map.put(deps, :io, %{read: read_fn})
      syndicate = Syndicate.new(name: "New Loka", id: :new_loka, catalog: [])

      # Act
      actual = FileSystem.list_products(syndicate, deps)
      expected = {:error, :enoent}

      # Assert
      assert actual == expected
    end
  end

  describe "list_orders/2" do
    test "returns list of available placed orders from given syndicate", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:current_orders])

        {:ok,
         "{\"new_loka\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"5ee71a2604d55c0a5cbdc3c2\"},{\"item_id\":\"Vampire leech\",\"order_id\":\"5ee71a2604d55c0a5cbdc3e3\"}]}"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})
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

      # Assert
      assert actual == expected
    end

    test "returns empty if syndicate is not found", %{paths: paths} = deps do
      # Arrange

      read_fn = fn filename ->
        assert filename == Path.join(paths[:current_orders])

        {:ok,
         "{\"red_veil\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"5ee71a2604d55c0a5cbdc3c2\"}]}"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})
      syndicate = Syndicate.new(name: "New Loka", id: :new_loka, catalog: [])

      # Act
      actual = FileSystem.list_orders(syndicate, deps)
      expected = {:ok, []}

      # Assert
      assert actual == expected
    end

    test "returns error if it cannot read file", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:current_orders])
        {:error, :enoent}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      syndicate = Syndicate.new(name: "New Loka", id: :new_loka, catalog: [])

      # Act
      actual = FileSystem.list_orders(syndicate, deps)
      expected = {:error, :enoent}

      # Assert
      assert actual == expected
    end
  end

  describe "save_order/3" do
    test "returns :ok if order was saved successfully", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:current_orders])

        {:ok,
         "{\"perrin_sequence\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"54a74454e779892d5e5155d5\"}]}"}
      end

      write_fn = fn filename, content ->
        assert filename == Path.join(paths[:current_orders])

        assert content ==
                 "{\"perrin_sequence\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"54a74454e779892d5e5155d5\"},{\"item_id\":\"Vampire leech\",\"order_id\":\"5ee71a2604d55c0a5cbdc3e3\"}]}"

        :ok
      end

      deps = Map.put(deps, :io, %{read: read_fn, write: write_fn})
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: [])

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "Vampire leech",
          "order_id" => "5ee71a2604d55c0a5cbdc3e3"
        })

      # Act & Assert
      assert FileSystem.save_order(placed_order, syndicate, deps) == :ok
    end

    test "returns error if it failed to read file", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:current_orders])
        {:error, :enoent}
      end

      deps = Map.put(deps, :io, %{read: read_fn})
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: [])

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "Vampire leech",
          "order_id" => "5ee71a2604d55c0a5cbdc3e3"
        })

      # Act & Assert
      assert FileSystem.save_order(placed_order, syndicate, deps) == {:error, :enoent}
    end

    test "returns error if it failed to save order", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:current_orders])

        {:ok,
         "{\"perrin_sequence\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"54a74454e779892d5e5155d5\"}]}"}
      end

      write_fn = fn filename, _content ->
        assert filename == Path.join(paths[:current_orders])
        {:error, :enoent}
      end

      deps = Map.put(deps, :io, %{read: read_fn, write: write_fn})
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: [])

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "Vampire leech",
          "order_id" => "5ee71a2604d55c0a5cbdc3e3"
        })

      # Act & Assert
      assert FileSystem.save_order(placed_order, syndicate, deps) == {:error, :enoent}
    end
  end

  describe "delete_order/3" do
    test "returns :ok if order was deleted successfully", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:current_orders])

        {:ok,
         "{\"perrin_sequence\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"54a74454e779892d5e5155d5\"}]}"}
      end

      write_fn = fn filename, content ->
        assert filename == Path.join(paths[:current_orders])
        assert content == "{\"perrin_sequence\":[]}"
        :ok
      end

      deps = Map.put(deps, :io, %{read: read_fn, write: write_fn})
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: [])

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "54e644ffe779897594fa68d2",
          "order_id" => "54a74454e779892d5e5155d5"
        })

      # Act & Assert
      assert FileSystem.delete_order(placed_order, syndicate, deps) == :ok
    end

    test "returns error if it fails to read file", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:current_orders])
        {:error, :enoent}
      end

      deps = Map.put(deps, :io, %{read: read_fn})
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: [])

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "54e644ffe779897594fa68d2",
          "order_id" => "54a74454e779892d5e5155d5"
        })

      # Act & Assert
      assert FileSystem.delete_order(placed_order, syndicate, deps) == {:error, :enoent}
    end

    test "returns error if it failed to save deleted order",
         %{paths: paths} = deps do
      # Arrange

      read_fn = fn filename ->
        assert filename == Path.join(paths[:current_orders])

        {:ok,
         "{\"perrin_sequence\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"54a74454e779892d5e5155d5\"}]}"}
      end

      write_fn = fn filename, content ->
        assert filename == Path.join(paths[:current_orders])
        assert content == "{\"perrin_sequence\":[]}"
        {:error, :enoent}
      end

      deps = Map.put(deps, :io, %{read: read_fn, write: write_fn})
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: [])

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "54e644ffe779897594fa68d2",
          "order_id" => "54a74454e779892d5e5155d5"
        })

      # Act & Assert
      assert FileSystem.delete_order(placed_order, syndicate, deps) == {:error, :enoent}
    end
  end

  describe "save_login_data/3" do
    test "returns :ok if write was successful", %{paths: paths} = deps do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      write_fn = fn filename, content ->
        assert filename == Path.join(paths[:setup])
        assert content == Jason.encode!(%{authorization: auth, user: user})
        :ok
      end

      deps = Map.put(deps, :io, %{write: write_fn})

      # Act & Assert
      assert FileSystem.save_login_data(auth, user, deps) == :ok
    end

    test "returns error if write to file failed", %{paths: paths} = deps do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      write_fn = fn filename, content ->
        assert filename == Path.join(paths[:setup])
        assert content == Jason.encode!(%{authorization: auth, user: user})
        {:error, :enoent}
      end

      deps = Map.put(deps, :io, %{write: write_fn})

      # Act
      actual = FileSystem.save_login_data(auth, user, deps)
      expected = {:error, :enoent}

      # Assert
      assert actual == expected
    end
  end

  describe "get_login_data/1" do
    test "returns login_data if read succeeded", %{paths: paths} = deps do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      read_fn = fn filename ->
        assert filename == Path.join(paths[:setup])

        {:ok,
         "{\"authorization\":{\"cookie\":\"a_cookie\",\"token\":\"a_token\"},\"user\":{\"ingame_name\":\"fl4m3\",\"patreon?\":false}}"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.get_login_data(deps) == {:ok, {auth, user}}
    end

    test "returns nil if read succeeded but authorization cookie is null",
         %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:setup])

        {:ok,
         "{\"authorization\":{\"cookie\": null,\"token\":\"a_token\"},\"user\":{\"ingame_name\":\"fl4m3\",\"patreon?\":false}}"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.get_login_data(deps) == {:ok, nil}
    end

    test "returns nil if read succeeded but authorization token is null",
         %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:setup])

        {:ok,
         "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": null},\"user\":{\"ingame_name\":\"fl4m3\",\"patreon?\":false}}"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.get_login_data(deps) == {:ok, nil}
    end

    test "returns nil if read succeeded but user ingame_name is null", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:setup])

        {:ok,
         "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": \"a_token\"},\"user\":{\"ingame_name\": null,\"patreon?\":false}}"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.get_login_data(deps) == {:ok, nil}
    end

    test "returns nil if read succeeded but user patreon? is null", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:setup])

        {:ok,
         "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": \"a_token\"},\"user\":{\"ingame_name\": \"fl4m3\",\"patreon?\": null}}"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.get_login_data(deps) == {:ok, nil}
    end

    test "returns nil if read succeeded but authorization is missing", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:setup])
        {:ok, "{\"user\":{\"ingame_name\": \"fl4m3\",\"patreon?\": false}}"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.get_login_data(deps) == {:ok, nil}
    end

    test "returns nil if read succeeded but user is missing", %{paths: paths} = deps do
      read_fn = fn filename ->
        assert filename == Path.join(paths[:setup])
        {:ok, "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": \"a_token\"}}"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.get_login_data(deps) == {:ok, nil}
    end
  end

  describe "delete_login_data/3" do
    test "returns :ok if write was successful", %{paths: paths} = deps do
      # Arrange
      write_fn = fn filename, content ->
        assert filename == Path.join(paths[:setup])
        assert content == "{}"
        :ok
      end

      deps = Map.put(deps, :io, %{write: write_fn})

      # Act & Assert
      assert FileSystem.delete_login_data(deps) == :ok
    end

    test "returns error if write to file failed", %{paths: paths} = deps do
      # Arrange
      write_fn = fn filename, content ->
        assert filename == Path.join(paths[:setup])
        assert content == "{}"
        {:error, :enoent}
      end

      deps = Map.put(deps, :io, %{write: write_fn})

      # Act & Assert
      assert FileSystem.delete_login_data(deps) == {:error, :enoent}
    end
  end

  describe "list_syndicates/1" do
    test "returns the list of all known syndicates", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:syndicates])

        {:ok,
         "[{\"id\":\"red_veil\",\"name\":\"Red Veil\",\"catalog\":[]},{\"id\":\"perrin_sequence\",\"name\":\"Perrin Sequence\",\"catalog\":[]}]"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.list_syndicates(deps) ==
               {:ok,
                [
                  %Syndicate{name: "Red Veil", id: :red_veil, catalog: []},
                  %Syndicate{name: "Perrin Sequence", id: :perrin_sequence, catalog: []}
                ]}
    end

    test "returns error if it cannot read file", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:syndicates])
        {:error, :enoent}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.list_syndicates(deps) == {:error, :enoent}
    end
  end

  describe "list_active_syndicates/1" do
    test "returns the list of all active syndicates", deps do
      # Arrange
      read_fn = fn
        "current_orders.json" ->
          {:ok,
           "{\"new_loka\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"5ee71a2604d55c0a5cbdc3c2\"},{\"item_id\":\"Vampire leech\",\"order_id\":\"5ee71a2604d55c0a5cbdc3e3\"}]}"}

        "syndicates.json" ->
          {:ok,
           "[{\"id\":\"new_loka\",\"name\":\"New Loka\",\"catalog\":[]},{\"id\":\"perrin_sequence\",\"name\":\"Perrin Sequence\",\"catalog\":[]}]"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.list_active_syndicates(deps) ==
               {:ok, [%Syndicate{name: "New Loka", id: :new_loka, catalog: []}]}
    end

    test "returns the error if it fails to read current_orders.json", deps do
      # Arrange
      read_fn = fn
        "current_orders.json" ->
          {:error, :enoent}

        "syndicates.json" ->
          {:ok,
           "[{\"id\":\"new_loka\",\"name\":\"New Loka\",\"catalog\":[]},{\"id\":\"perrin_sequence\",\"name\":\"Perrin Sequence\",\"catalog\":[]}]"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.list_active_syndicates(deps) == {:error, :enoent}
    end

    test "returns the error if it fails to read syndicates.json", deps do
      read_fn = fn
        "current_orders.json" ->
          {:ok,
           "{\"new_loka\":[{\"item_id\":\"54e644ffe779897594fa68d2\",\"order_id\":\"5ee71a2604d55c0a5cbdc3c2\"},{\"item_id\":\"Vampire leech\",\"order_id\":\"5ee71a2604d55c0a5cbdc3e3\"}]}"}

        "syndicates.json" ->
          {:error, :enoent}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.list_active_syndicates(deps) == {:error, :enoent}
    end
  end
end
