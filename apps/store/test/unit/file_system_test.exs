defmodule MarketManager.Store.FileSystemTest do
  @moduledoc false

  use ExUnit.Case

  import Mock

  alias Jason
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
    test_with_mock "returns :ok if cwd and login data were successful", File,
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

    test_with_mock "returns nil if cwd and read succeeded but authorization is null",
                   File,
                   cwd: fn -> {:ok, "home/user"} end,
                   read: fn _file_name ->
                     {:ok,
                      "{\"authorization\": null,\"user\":{\"ingame_name\": \"fl4m3\",\"patreon?\": false}}"}
                   end do
      # Act
      actual = FileSystem.get_login_data()
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called(File.cwd())
      assert_called(File.read(:_))
    end

    test_with_mock "returns nil if cwd and read succeeded but user is null",
                   File,
                   cwd: fn -> {:ok, "home/user"} end,
                   read: fn _file_name ->
                     {:ok,
                      "{\"authorization\":{\"cookie\": \"a_cookie\",\"token\": \"a_token\"},\"user\": null}"}
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
end
