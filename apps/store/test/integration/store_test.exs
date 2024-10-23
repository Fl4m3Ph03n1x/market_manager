defmodule StoreTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Shared.Data.{Authorization, Product, User}
  alias Store

  ##########
  # Setup  #
  ##########

  @watch_list_file :store |> Application.compile_env!(:watch_list) |> Path.join()
  @setup_file :store |> Application.compile_env!(:setup) |> Path.join()

  defp create_watch_list_file do
    content =
      Jason.encode!(%{
        active_syndicates: %{
          cephalon_suda: :lowest_minus_one,
          cephalon_simaris: :equal_to_lowest
        }
      })

    File.write(@watch_list_file, content)
  end

  defp reset_watch_list_file do
    content = Jason.encode!(%{active_syndicates: %{}})
    File.write(@watch_list_file, content)
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
    test "returns list of available products from the syndicates with the given ids" do
      # Arrange
      syndicate_ids = [:cephalon_simaris, :arbitrations]

      # Act & Assert
      assert Store.list_products(syndicate_ids) ==
               {:ok,
                [
                  %Product{
                    default_price: 60,
                    id: "5740c1879d238d4a03d28518",
                    min_price: 50,
                    name: "Looter",
                    quantity: 1,
                    rank: 0
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 60,
                    min_price: 50,
                    id: "554d3f0ce779894445a848f2",
                    name: "Detect Vulnerability"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 60,
                    min_price: 50,
                    id: "5b00231bac0f7e006fd6f7b3",
                    name: "Reawaken"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 60,
                    min_price: 50,
                    id: "5b00231bac0f7e006fd6f7b4",
                    name: "Negate"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 60,
                    min_price: 50,
                    id: "5bc24accb919f2010f7d579a",
                    name: "Ambush"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 60,
                    min_price: 50,
                    id: "5bc24accb919f2010f7d579b",
                    name: "Energy Generator"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 60,
                    min_price: 50,
                    id: "5f533a19d5c36d0157f4b9ff",
                    name: "Botanist"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 60,
                    min_price: 50,
                    id: "56dac8cc5cc639de0a45c52c",
                    name: "Energy Conversion"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 60,
                    min_price: 50,
                    id: "56dac8d25cc639de0a45c52d",
                    name: "Health Conversion"
                  },
                  %Product{
                    default_price: 60,
                    id: "588a789c3cf52c408a2f88dc",
                    min_price: 50,
                    name: "Astral Autopsy",
                    quantity: 1,
                    rank: "n/a"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 11,
                    min_price: 9,
                    id: "5bc1ab93b919f200c18c10f0",
                    name: "Sharpshooter"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 16,
                    min_price: 14,
                    id: "5bc1ab94b919f200c18c10f2",
                    name: "Cautious Shot"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 16,
                    min_price: 14,
                    id: "5bc1ab93b919f200c18c10f1",
                    name: "Power Donation"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 16,
                    min_price: 15,
                    id: "5bc1ab92b919f200c18c10ed",
                    name: "Vigorous Swap"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 16,
                    min_price: 15,
                    id: "5bc1ab92b919f200c18c10ee",
                    name: "Rolling Guard"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 19,
                    min_price: 17,
                    id: "5e7caa01267539063de48c3e",
                    name: "Preparation"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 20,
                    min_price: 16,
                    id: "5e7caa01267539063de48c3f",
                    name: "Aerial Ace"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 20,
                    min_price: 18,
                    id: "5e7caa01267539063de48c3c",
                    name: "Mending Shot"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 21,
                    min_price: 19,
                    id: "5e7caa02267539063de48c40",
                    name: "Energizing Shot"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 16,
                    min_price: 14,
                    id: "60e5b9004794450053e9995b",
                    name: "Galvanized Savvy"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 16,
                    min_price: 15,
                    id: "60e5b8fd4794450053e99948",
                    name: "Galvanized Acceleration"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 16,
                    min_price: 14,
                    id: "60e5b8fb4794450053e9993d",
                    name: "Galvanized Hell"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 16,
                    min_price: 14,
                    id: "60e5b8fd4794450053e99944",
                    name: "Galvanized Aptitude"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 16,
                    min_price: 14,
                    id: "60e5b9014794450053e99961",
                    name: "Galvanized Chamber"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 16,
                    min_price: 14,
                    id: "60e5b8fe4794450053e9994d",
                    name: "Galvanized Crosshairs"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 16,
                    min_price: 14,
                    id: "60e5b8ff4794450053e99953",
                    name: "Galvanized Shot"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 17,
                    min_price: 15,
                    id: "60e5b8fc4794450053e99941",
                    name: "Galvanized Diffusion"
                  },
                  %Product{
                    rank: 0,
                    quantity: 1,
                    default_price: 17,
                    min_price: 15,
                    id: "60e5b8fd4794450053e99947",
                    name: "Galvanized Scope"
                  }
                ]}
    end
  end

  describe "get_product_by_id/1" do
    test "returns product with given id" do
      # Arrange
      product_id = "5740c1879d238d4a03d28518"

      # Act
      actual = Store.get_product_by_id(product_id)

      expected =
        {:ok,
         Product.new(%{
           "name" => "Looter",
           "id" => "5740c1879d238d4a03d28518",
           "min_price" => 50,
           "default_price" => 60,
           "quantity" => 1,
           "rank" => 0
         })}

      # Assert
      assert actual == expected
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

  describe "activate_syndicates/1" do
    setup do
      create_watch_list_file()
      on_exit(&reset_watch_list_file/0)
    end

    test "marks the given syndicates as active with the given strategy" do
      # Act & Assert
      assert Store.activate_syndicates(%{
               new_loka: :top_three_average,
               red_veil: :top_five_average
             }) == :ok

      assert Store.list_active_syndicates() ==
               {:ok,
                %{
                  new_loka: :top_three_average,
                  red_veil: :top_five_average,
                  cephalon_suda: :lowest_minus_one,
                  cephalon_simaris: :equal_to_lowest
                }}
    end

    test "overwrites strategy for the given syndicate if it is already active" do
      # Act & Assert

      assert Store.activate_syndicates(%{
               new_loka: :top_five_average,
               cephalon_suda: :top_five_average
             }) == :ok

      assert Store.activate_syndicates(%{new_loka: :top_three_average}) == :ok

      assert Store.list_active_syndicates() ==
               {:ok,
                %{
                  new_loka: :top_three_average,
                  cephalon_suda: :top_five_average,
                  cephalon_simaris: :equal_to_lowest
                }}
    end
  end

  describe "deactivate_syndicates/1" do
    setup do
      create_watch_list_file()
      on_exit(&reset_watch_list_file/0)
    end

    test "removes the syndicates from active list" do
      # Act & Assert
      assert Store.deactivate_syndicates([:cephalon_suda]) == :ok

      assert Store.list_active_syndicates() ==
               {:ok,
                %{
                  cephalon_simaris: :equal_to_lowest
                }}
    end
  end

  describe "list_active_syndicates/0" do
    setup do
      create_watch_list_file()
      on_exit(&reset_watch_list_file/0)
    end

    test "returns list of active syndicates" do
      # Act & Assert
      assert Store.list_active_syndicates() ==
               {:ok,
                %{
                  cephalon_suda: :lowest_minus_one,
                  cephalon_simaris: :equal_to_lowest
                }}
    end

    test "returns empty list if no syndicates are active" do
      # Arrange
      reset_watch_list_file()

      # Act & Assert
      assert Store.list_active_syndicates() == {:ok, %{}}
    end
  end
end
