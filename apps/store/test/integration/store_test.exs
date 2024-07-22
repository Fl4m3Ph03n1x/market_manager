defmodule StoreTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Shared.Data.{Authorization, PlacedOrder, Product, Syndicate, User}
  alias Store

  ##########
  # Setup  #
  ##########

  @current_orders_file :store |> Application.compile_env!(:current_orders) |> Path.join()
  @setup_file :store |> Application.compile_env!(:setup) |> Path.join()

  defp create_current_orders_file do
    content =
      Jason.encode!(%{
        manual: [
          %PlacedOrder{
            item_id: "5740c1879d238d4a03d28518",
            order_id: "5ee71a2604d55c0a5cbdc3c2"
          }
        ],
        automatic: [
          %PlacedOrder{
            item_id: "5740c1879d238d4a03d28518",
            order_id: "5ee71a2604d55c0a5cbdc3e3"
          },
          %PlacedOrder{
            item_id: "54a74454e779892d5e5155be",
            order_id: "5ee71a2604d55c0a5cbdc3d4"
          }
        ],
        active_syndicates: [:cephalon_simaris, :cephalon_suda]
      })

    File.write(@current_orders_file, content)
  end

  defp reset_current_orders_file do
    content =
      Jason.encode!(%{
        "manual" => [],
        "automatic" => [],
        "active_syndicates" => []
      })

    File.write(@current_orders_file, content)
  end

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

  defp reset_setup_file do
    content =
      Jason.encode!(%{
        "authorization" => %{},
        "user" => %{}
      })

    File.write(@setup_file, content)
  end

  ##########
  # Tests  #
  ##########

  describe "list_products/1" do
    test "returns list of available products from given syndicate" do
      # Arrange
      syndicate =
        Syndicate.new(
          name: "Cephalon Simaris",
          id: :cephalon_simaris,
          catalog: ["5740c1879d238d4a03d28518", "588a789c3cf52c408a2f88dc"]
        )

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
      on_exit(&reset_current_orders_file/0)
    end

    test "returns list of available orders from given syndicate" do
      # Act
      actual = Store.list_sell_orders()

      expected = {
        :ok,
        %{
          manual: [
            %PlacedOrder{
              item_id: "5740c1879d238d4a03d28518",
              order_id: "5ee71a2604d55c0a5cbdc3c2"
            }
          ],
          automatic: [
            %PlacedOrder{
              item_id: "5740c1879d238d4a03d28518",
              order_id: "5ee71a2604d55c0a5cbdc3e3"
            },
            %PlacedOrder{
              item_id: "54a74454e779892d5e5155be",
              order_id: "5ee71a2604d55c0a5cbdc3d4"
            }
          ]
        }
      }

      # Assert
      assert actual == expected
    end
  end

  describe "reset_orders/0" do
    setup do
      create_current_orders_file()
      on_exit(&reset_current_orders_file/0)
    end

    test "returns OK if all orders were reset successfully" do
      # Act
      assert Store.reset_orders() == :ok

      {:ok, content} =
        @current_orders_file
        |> File.read!()
        |> Jason.decode()

      # Assert
      assert content == %{"manual" => [], "automatic" => [], "active_syndicates" => []}
    end
  end

  describe "save_order/2" do
    setup do
      create_current_orders_file()
      on_exit(&reset_current_orders_file/0)
    end

    test "returns order_id if manual order was saved successfully" do
      # Arrange
      syndicate = nil

      placed_order =
        %PlacedOrder{
          item_id: "6604a66edbdd5c1673781db9",
          order_id: "5ee71a2604d55c0a5cbdc4d3"
        }

      # Act & Assert
      assert Store.save_order(placed_order, syndicate) == :ok

      {:ok, content} =
        @current_orders_file
        |> File.read!()
        |> Jason.decode()

      assert content ==
               %{
                 "manual" => [
                   %{
                     "item_id" => "6604a66edbdd5c1673781db9",
                     "order_id" => "5ee71a2604d55c0a5cbdc4d3"
                   },
                   %{
                     "item_id" => "5740c1879d238d4a03d28518",
                     "order_id" => "5ee71a2604d55c0a5cbdc3c2"
                   }
                 ],
                 "automatic" => [
                   %{
                     "item_id" => "5740c1879d238d4a03d28518",
                     "order_id" => "5ee71a2604d55c0a5cbdc3e3"
                   },
                   %{
                     "item_id" => "54a74454e779892d5e5155be",
                     "order_id" => "5ee71a2604d55c0a5cbdc3d4"
                   }
                 ],
                 "active_syndicates" => ["cephalon_simaris", "cephalon_suda"]
               }
    end

    test "returns order_id if automatic order was saved successfully" do
      # Arrange
      syndicate = :perrin_sequence

      placed_order =
        PlacedOrder.new(%{
          "item_id" => "6604a66edbdd5c1673781db9",
          "order_id" => "5ee71a2604d55c0a5cbdc4d3"
        })

      # Act & Assert
      assert Store.save_order(placed_order, syndicate) == :ok

      {:ok, content} =
        @current_orders_file
        |> File.read!()
        |> Jason.decode()

      assert content ==
               %{
                 "manual" => [
                   %{
                     "item_id" => "5740c1879d238d4a03d28518",
                     "order_id" => "5ee71a2604d55c0a5cbdc3c2"
                   }
                 ],
                 "automatic" => [
                   %{
                     "item_id" => "6604a66edbdd5c1673781db9",
                     "order_id" => "5ee71a2604d55c0a5cbdc4d3"
                   },
                   %{
                     "item_id" => "5740c1879d238d4a03d28518",
                     "order_id" => "5ee71a2604d55c0a5cbdc3e3"
                   },
                   %{
                     "item_id" => "54a74454e779892d5e5155be",
                     "order_id" => "5ee71a2604d55c0a5cbdc3d4"
                   }
                 ],
                 "active_syndicates" => ["perrin_sequence", "cephalon_simaris", "cephalon_suda"]
               }
    end
  end

  describe "delete_order/2" do
    setup do
      create_current_orders_file()
      on_exit(&reset_current_orders_file/0)
    end

    test "returns :ok if manual order was deleted successfully" do
      # Arrange
      syndicate = nil

      placed_order =
        %PlacedOrder{
          item_id: "5740c1879d238d4a03d28518",
          order_id: "5ee71a2604d55c0a5cbdc3c2"
        }

      # Act & Assert
      assert Store.delete_order(placed_order, syndicate) == :ok

      {:ok, content} =
        @current_orders_file
        |> File.read!()
        |> Jason.decode()

      assert content ==
               %{
                 "manual" => [],
                 "automatic" => [
                   %{
                     "item_id" => "5740c1879d238d4a03d28518",
                     "order_id" => "5ee71a2604d55c0a5cbdc3e3"
                   },
                   %{
                     "item_id" => "54a74454e779892d5e5155be",
                     "order_id" => "5ee71a2604d55c0a5cbdc3d4"
                   }
                 ],
                 "active_syndicates" => ["cephalon_simaris", "cephalon_suda"]
               }
    end

    test "returns :ok if automatic order was deleted successfully" do
      # Arrange
      syndicate = :cephalon_simaris

      placed_order =
        %PlacedOrder{
          item_id: "5740c1879d238d4a03d28518",
          order_id: "5ee71a2604d55c0a5cbdc3e3"
        }

      # Act & Assert
      assert Store.delete_order(placed_order, syndicate) == :ok

      {:ok, content} =
        @current_orders_file
        |> File.read!()
        |> Jason.decode()

      assert content ==
               %{
                 "manual" => [
                   %{
                     "item_id" => "5740c1879d238d4a03d28518",
                     "order_id" => "5ee71a2604d55c0a5cbdc3c2"
                   }
                 ],
                 "automatic" => [
                   %{
                     "item_id" => "54a74454e779892d5e5155be",
                     "order_id" => "5ee71a2604d55c0a5cbdc3d4"
                   }
                 ],
                 "active_syndicates" => ["cephalon_suda"]
               }
    end
  end

  describe "save_login_data/2" do
    setup do
      create_setup_file()
      on_exit(&reset_setup_file/0)
    end

    test "returns :ok if login data was saved successfully" do
      # Arrange
      auth = Authorization.new(%{"cookie" => "new_cookie", "token" => "new_token"})
      user = User.new(%{"ingame_name" => "ph03n1x", "patreon?" => true})

      # Act & Assert
      assert Store.save_login_data(auth, user) == :ok

      {:ok, content} = File.read(@setup_file)

      assert Jason.decode!(content) ==
               %{
                 "user" => %{"ingame_name" => "ph03n1x", "patreon?" => true},
                 "authorization" => %{"cookie" => "new_cookie", "token" => "new_token"}
               }
    end
  end

  describe "delete_login_data/0" do
    setup do
      create_setup_file()
      on_exit(&reset_setup_file/0)
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
      on_exit(&reset_setup_file/0)
    end

    test "returns login data" do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      # Act & Assert
      assert Store.get_login_data() == {:ok, {auth, user}}
    end
  end

  describe "list_syndicates/0" do
    test "returns list of all syndicates" do
      # Act
      {:ok, syndicates} = Store.list_syndicates()

      [arbiters, arbitrations, simaris, suda, new_loka, perrin_sequence, red_veil, steel_meridian] =
        Enum.sort_by(syndicates, & &1.id)

      # Assert
      assert arbiters.id == :arbiters_of_hexis
      assert arbiters.name == "Arbiters of Hexis"

      assert arbitrations.id == :arbitrations
      assert arbitrations.name == "Arbitrations"

      assert simaris.id == :cephalon_simaris
      assert simaris.name == "Cephalon Simaris"

      assert suda.id == :cephalon_suda
      assert suda.name == "Cephalon Suda"

      assert new_loka.id == :new_loka
      assert new_loka.name == "New Loka"

      assert perrin_sequence.id == :perrin_sequence
      assert perrin_sequence.name == "Perrin Sequence"

      assert red_veil.id == :red_veil
      assert red_veil.name == "Red Veil"

      assert steel_meridian.id == :steel_meridian
      assert steel_meridian.name == "Steel Meridian"
    end
  end

  describe "list_active_syndicates/0" do
    setup do
      create_current_orders_file()
      on_exit(&reset_current_orders_file/0)
    end

    test "returns list of active syndicates" do
      # Act
      {:ok, [synd1, synd2]} = Store.list_active_syndicates()

      # Assert
      assert synd1.id == :cephalon_simaris
      assert synd2.id == :cephalon_suda
    end

    test "returns empty list if no syndicates are active" do
      # Arrange
      reset_current_orders_file()

      # Act
      {:ok, syndicates} = Store.list_active_syndicates()

      # Assert
      assert syndicates == []
    end
  end
end
