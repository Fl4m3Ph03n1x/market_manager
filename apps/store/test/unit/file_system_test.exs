defmodule MarketManager.Store.FileSystemTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Jason
  alias Shared.Data.{Authorization, Product, Syndicate, User}
  alias Store.FileSystem

  setup do
    %{
      paths: [
        watch_list: ["watch_list.json"],
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

  describe "get_product_by_id/2" do
    test "returns the product with the given id", %{paths: paths} = deps do
      # Arrange
      read_fn = fn filename ->
        assert filename == Path.join(paths[:products])

        {:ok,
         "[{\"name\": \"Gleaming Blight\",\"id\": \"54a74454e779892d5e5155d5\",\"min_price\": 14,\"default_price\": 16,\"quantity\": 1, \"rank\": 0}]"}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      product_id = "54a74454e779892d5e5155d5"

      # Act
      actual = FileSystem.get_product_by_id(product_id, deps)

      expected =
        {:ok,
         Product.new(%{
           "id" => "54a74454e779892d5e5155d5",
           "name" => "Gleaming Blight",
           "min_price" => 14,
           "default_price" => 16,
           "quantity" => 1,
           "rank" => 0
         })}

      # Assert
      assert actual == expected
    end

    test "returns error if product is not found", %{paths: paths} = deps do
      # Arrange
      deps =
        Map.put(deps, :io, %{
          read: fn filename ->
            assert filename == Path.join(paths[:products])
            {:ok, "[]"}
          end
        })

      product_id = "54a74454e779892d5e5155d5"

      # Act
      actual = FileSystem.get_product_by_id(product_id, deps)
      expected = {:error, :product_not_found}

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
      product_id = "54a74454e779892d5e5155d5"

      # Act
      actual = FileSystem.get_product_by_id(product_id, deps)
      expected = {:error, :enoent}

      # Assert
      assert actual == expected
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

  describe "activate_syndicates/2" do
    test "activates the given syndicates with the given strategies", deps do
      # Arrange
      syndicates = [:cephalon_simaris, :cephalon_suda]
      strategy = :top_five_average

      io_stubs = %{
        read: fn "watch_list.json" -> {:ok, "{\"active_syndicates\": {}}"} end,
        write: fn "watch_list.json", data ->
          assert data ==
                   Jason.encode!(%{
                     active_syndicates: %{
                       cephalon_simaris: strategy,
                       cephalon_suda: strategy
                     }
                   })

          :ok
        end
      }

      deps = Map.put(deps, :io, io_stubs)

      # Act & Assert
      assert FileSystem.activate_syndicates(syndicates, strategy, deps) == :ok
    end

    test "returns the error if it fails to read watch_list.json", deps do
      # Arrange
      io_stubs = %{
        read: fn "watch_list.json" -> {:error, :enoent} end
      }

      deps = Map.put(deps, :io, io_stubs)

      # Act & Assert
      assert FileSystem.activate_syndicates([:new_loka], :top_five_average, deps) ==
               {:error, :enoent}
    end

    test "returns the error if it fails to write to watch_list.json", deps do
      # Arrange
      io_stubs = %{
        read: fn "watch_list.json" -> {:ok, "{\"active_syndicates\": {}}"} end,
        write: fn "watch_list.json", _data -> {:error, :enoent} end
      }

      deps = Map.put(deps, :io, io_stubs)

      # Act & Assert
      assert FileSystem.activate_syndicates([:new_loka], :top_five_average, deps) ==
               {:error, :enoent}
    end
  end

  describe "deactivate_syndicates/1" do
    test "deactivates the syndicates with the given ids", deps do
      # Arrange
      syndicates = [:cephalon_simaris, :cephalon_suda]

      io_stubs = %{
        read: fn "watch_list.json" ->
          {:ok,
           Jason.encode!(%{
             active_syndicates: %{
               cephalon_simaris: :top_five_average,
               cephalon_suda: :top_five_average
             }
           })}
        end,
        write: fn "watch_list.json", data ->
          assert data ==
                   Jason.encode!(%{active_syndicates: %{}})

          :ok
        end
      }

      deps = Map.put(deps, :io, io_stubs)

      # Act & Assert
      assert FileSystem.deactivate_syndicates(syndicates, deps) == :ok
    end

    test "returns the error if it fails to read watch_list.json", deps do
      # Arrange
      io_stubs = %{
        read: fn "watch_list.json" -> {:error, :enoent} end
      }

      deps = Map.put(deps, :io, io_stubs)

      # Act & Assert
      assert FileSystem.deactivate_syndicates([:new_loka], deps) == {:error, :enoent}
    end

    test "returns the error if it fails to write to watch_list.json", deps do
      # Arrange
      io_stubs = %{
        read: fn "watch_list.json" -> {:ok, "{\"active_syndicates\": {}}"} end,
        write: fn "watch_list.json", _data -> {:error, :enoent} end
      }

      deps = Map.put(deps, :io, io_stubs)

      # Act & Assert
      assert FileSystem.deactivate_syndicates([:new_loka], deps) == {:error, :enoent}
    end
  end

  describe "list_active_syndicates/1" do
    test "returns the list of all active syndicates", deps do
      # Arrange
      read_fn = fn
        "watch_list.json" ->
          {:ok,
           Jason.encode!(%{
             active_syndicates: %{
               cephalon_simaris: :top_five_average,
               cephalon_suda: :top_five_average
             }
           })}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.list_active_syndicates(deps) ==
               {:ok,
                %{
                  cephalon_simaris: :top_five_average,
                  cephalon_suda: :top_five_average
                }}
    end

    test "returns the error if it fails to read watch_list.json", deps do
      read_fn = fn
        "watch_list.json" -> {:error, :enoent}
      end

      deps = Map.put(deps, :io, %{read: read_fn})

      # Act & Assert
      assert FileSystem.list_active_syndicates(deps) == {:error, :enoent}
    end
  end
end
