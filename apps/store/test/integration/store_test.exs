defmodule StoreTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.{Authorization, PlacedOrder, Product, Syndicate, User}
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
        "cephalon_simaris" => [
          Product.new(%{
            "name" => "Looter",
            "id" => "5740c1879d238d4a03d28518",
            "min_price" => 50,
            "default_price" => 60,
            "quantity" => 1,
            "rank" => 0
          }),
          Product.new(%{
            "name" => "Astral Autopsy",
            "id" => "588a789c3cf52c408a2f88dc",
            "min_price" => 50,
            "default_price" => 60,
            "quantity" => 1,
            "rank" => "n/a"
          })
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
        "cephalon_simaris" => [
          PlacedOrder.new(%{
            "item_id" => "5740c1879d238d4a03d28518",
            "order_id" => "5ee71a2604d55c0a5cbdc3c2"
          }),
          PlacedOrder.new(%{
            "item_id" => "5b00231bac0f7e006fd6f7b4",
            "order_id" => "5ee71a2604d55c0a5cbdc3e3"
          })
        ]
      })

    File.write(@current_orders_file, content)
  end

  defp delete_current_orders_file, do: File.rm!(@current_orders_file)

  defp create_setup_file do
    content =
      Jason.encode!(%{
        "authorization" => %{
          "cookie" => "a_cookie",
          "token" => "a_token"
        },
        "user" => %{
          "ingame_name" => "fl4m3",
          "patreon?" => false
        }
      })

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
      syndicate = Syndicate.new(name: "Cephalon Simaris", id: :cephalon_simaris)

      # Act
      actual = Store.list_products(syndicate)

      expected =
        {:ok,
         [
           Product.new(%{
             "name" => "Looter",
             "id" => "5740c1879d238d4a03d28518",
             "min_price" => 50,
             "default_price" => 60,
             "quantity" => 1,
             "rank" => 0
           }),
           Product.new(%{
             "name" => "Astral Autopsy",
             "id" => "588a789c3cf52c408a2f88dc",
             "min_price" => 50,
             "default_price" => 60,
             "quantity" => 1,
             "rank" => "n/a"
           })
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
      syndicate = Syndicate.new(name: "Cephalon Simaris", id: :cephalon_simaris)

      # Act
      actual = Store.list_orders(syndicate)

      expected = {
        :ok,
        [
          PlacedOrder.new(%{
            "item_id" => "5740c1879d238d4a03d28518",
            "order_id" => "5ee71a2604d55c0a5cbdc3c2"
          }),
          PlacedOrder.new(%{
            "item_id" => "5b00231bac0f7e006fd6f7b4",
            "order_id" => "5ee71a2604d55c0a5cbdc3e3"
          })
        ]
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
      syndicate = Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence)

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "54e644ffe779897594fa68d2",
          "order_id" => "54a74454e779892d5e5155d5"
        })

      # Act & Assert
      assert Store.save_order(placed_order, syndicate) == :ok
      {:ok, content} = File.read(@current_orders_file)

      assert content ==
               Jason.encode!(%{
                 "new_loka" => [],
                 "perrin_sequence" => [
                   PlacedOrder.new(%{
                     "item_id" => "54e644ffe779897594fa68d2",
                     "order_id" => "54a74454e779892d5e5155d5"
                   })
                 ],
                 "red_veil" => [],
                 "cephalon_simaris" => [
                   PlacedOrder.new(%{
                     "item_id" => "5740c1879d238d4a03d28518",
                     "order_id" => "5ee71a2604d55c0a5cbdc3c2"
                   }),
                   PlacedOrder.new(%{
                     "item_id" => "5b00231bac0f7e006fd6f7b4",
                     "order_id" => "5ee71a2604d55c0a5cbdc3e3"
                   })
                 ]
               })
    end
  end

  describe "delete_order/2" do
    setup do
      create_current_orders_file()
      on_exit(&delete_current_orders_file/0)
    end

    test "returns :ok if order was deleted successfully" do
      # Arrange
      syndicate = Syndicate.new(name: "Cephalon Simaris", id: :cephalon_simaris)

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "5740c1879d238d4a03d28518",
          "order_id" => "5ee71a2604d55c0a5cbdc3c2"
        })

      # Act & Assert
      assert Store.delete_order(placed_order, syndicate) == :ok
      {:ok, content} = File.read(@current_orders_file)

      assert content ==
               Jason.encode!(%{
                 "new_loka" => [],
                 "perrin_sequence" => [],
                 "red_veil" => [],
                 "cephalon_simaris" => [
                   PlacedOrder.new(%{
                     "item_id" => "5b00231bac0f7e006fd6f7b4",
                     "order_id" => "5ee71a2604d55c0a5cbdc3e3"
                   })
                 ]
               })
    end
  end

  describe "save_login_data/2" do
    setup do
      create_setup_file()
      on_exit(&delete_setup_file/0)
    end

    test "returns :ok if login data was saved successfully" do
      # Arrange
      auth = Authorization.new(%{"cookie" => "new_cookie", "token" => "new_token"})
      user = User.new(%{"ingame_name" => "ph03n1x", "patreon?" => true})

      # Act & Assert
      assert Store.save_login_data(auth, user) == :ok

      {:ok, content} = File.read(@setup_file)

      assert content ==
               Jason.encode!(%{
                 "authorization" => %{"cookie" => "new_cookie", "token" => "new_token"},
                 "user" => %{"ingame_name" => "ph03n1x", "patreon?" => true}
               })
    end
  end

  describe "delete_login_data/0" do
    setup do
      create_setup_file()
      on_exit(&delete_setup_file/0)
    end

    test "returns :ok if login data was deleted" do
      # Act & Assert
      assert Store.delete_login_data() == :ok

      {:ok, content} = File.read(@setup_file)
      assert content == "{}"
    end
  end

  describe "get_login_data/0" do
    setup do
      create_setup_file()
      on_exit(&delete_setup_file/0)
    end

    test "returns login data" do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      # Act & Assert
      assert Store.get_login_data() == {:ok, {auth, user}}
    end
  end
end
