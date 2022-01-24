defmodule StoreTest do
  use ExUnit.Case

  alias Store

  ##########
  # Setup  #
  ##########

  @products_file Application.compile_env!(:store, :products)
  @current_orders_file Application.compile_env!(:store, :current_orders)
  @setup_file Application.compile_env!(:store, :setup)

  defp create_products_file do
    content =
      Jason.encode!(%{
        "simaris" => [
          %{
              "name" => "Looter",
              "id" => "5740c1879d238d4a03d28518",
              "price" => 50
          },
          %{
              "name" => "Astral Autopsy",
              "id" => "588a789c3cf52c408a2f88dc",
              "price" => 50,
              "rank" => "n/a"
          }
        ]
      })

    File.write(@products_file, content)
  end

  defp delete_products_file, do: File.rm!(@products_file)

  defp create_current_orders_file do
    content =
      Jason.encode!(%{
        "new_loka" => [],
        "perrin_sequence" => [],
        "red_veil" => [],
        "simaris" => ["5ee71a2604d55c0a5cbdc3c2", "5ee71a2604d55c0a5cbdc3e3"]
      })

    File.write(@current_orders_file, content)
  end

  defp delete_current_orders_file, do: File.rm!(@current_orders_file)

  defp create_setup_file do
    content = Jason.encode!(%{"cookie" => "a_cookie", "token" => "a_token"})
    File.write(@setup_file, content)
  end

  defp delete_setup_file, do: File.rm!(@setup_file)

  ##########
  # Tests  #
  ##########

  describe "list_products/1" do
    setup do
      create_products_file()
      on_exit(&delete_products_file/0)
    end

    test "returns list of available products from given syndicate" do
      # Arrange
      syndicate = "simaris"

      # Act
      actual = Store.list_products(syndicate)

      expected =
        {:ok, [
          %{
            "name" => "Looter",
            "id" => "5740c1879d238d4a03d28518",
            "price" => 50
          },
          %{
            "name" => "Astral Autopsy",
            "id" => "588a789c3cf52c408a2f88dc",
            "price" => 50,
            "rank" => "n/a"
          }
        ]}

      # Assert
      assert actual == expected
    end
  end

  describe "list_orders/1" do
    setup do
      create_current_orders_file()
      on_exit(&delete_current_orders_file/0)
    end

    test "returns list of available orders from given syndicate" do
      # Arrange
      syndicate = "simaris"

      # Act
      actual = Store.list_orders(syndicate)

      expected = {
        :ok,
        ["5ee71a2604d55c0a5cbdc3c2", "5ee71a2604d55c0a5cbdc3e3"]
      }

      # Assert
      assert actual == expected
    end
  end

  describe "save_order/2" do
    setup do
      create_current_orders_file()
      on_exit(&delete_current_orders_file/0)
    end

    test "returns order_id if order was saved successfully" do
      # Arrange
      syndicate = "perrin_sequence"
      order_id = "54a74454e779892d5e5155d5"

      # Act
      actual = Store.save_order(order_id, syndicate)
      expected = {:ok, order_id}

      # Assert
      assert actual == expected
    end
  end

  describe "delete_order/2" do
    setup do
      create_current_orders_file()
      on_exit(&delete_current_orders_file/0)
    end

    test "returns order_id if order was deleted successfully" do
      # Arrange
      syndicate = "simaris"
      order_id = "5ee71a2604d55c0a5cbdc3c2"

      # Act
      actual = Store.delete_order(order_id, syndicate)
      expected = {:ok, order_id}

      # Assert
      assert actual == expected
    end
  end

  describe "save_credentials/2" do
    setup do
      on_exit(&delete_setup_file/0)
    end

    test "returns login_info if login_info was saved successfully" do
      # Arrange
      login_info = %{"token" => "a_token", "cookie" => "a_cookie"}

      # Act
      actual = Store.save_credentials(login_info)
      expected = {:ok, login_info}

      # Assert
      assert actual == expected
    end
  end

  describe "get_credentials/0" do
    setup do
      create_setup_file()
      on_exit(&delete_setup_file/0)
    end

    test "returns login_info if login_info" do
      # Arrange
      login_info = %{"token" => "a_token", "cookie" => "a_cookie"}

      # Act
      actual = Store.get_credentials()
      expected = {:ok, login_info}

      # Assert
      assert actual == expected
    end
  end
end
