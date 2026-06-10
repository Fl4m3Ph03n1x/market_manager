defmodule StoreTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Shared.Data.{Authorization, User}
  alias Shared.Data.Product.{Arcane, Mod, ModWithoutRank}
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
          "ingame_name" => "Fl4m3",
          "slug" => "fl4m3",
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
      syndicate_ids = [:cephalon_simaris, :the_hex]

      # Act & Assert
      assert Store.list_products(syndicate_ids) ==
               {:ok,
                [
                  %Mod{
                    default_price: 60,
                    id: "5740c1879d238d4a03d28518",
                    min_price: 50,
                    name: "Looter"
                  },
                  %Mod{
                    default_price: 60,
                    min_price: 50,
                    id: "554d3f0ce779894445a848f2",
                    name: "Detect Vulnerability"
                  },
                  %Mod{
                    default_price: 60,
                    min_price: 50,
                    id: "5b00231bac0f7e006fd6f7b3",
                    name: "Reawaken"
                  },
                  %Mod{
                    default_price: 60,
                    min_price: 50,
                    id: "5b00231bac0f7e006fd6f7b4",
                    name: "Negate"
                  },
                  %Mod{
                    default_price: 60,
                    min_price: 50,
                    id: "5bc24accb919f2010f7d579a",
                    name: "Ambush"
                  },
                  %Mod{
                    default_price: 60,
                    min_price: 50,
                    id: "5bc24accb919f2010f7d579b",
                    name: "Energy Generator"
                  },
                  %Mod{
                    default_price: 60,
                    min_price: 50,
                    id: "5f533a19d5c36d0157f4b9ff",
                    name: "Botanist"
                  },
                  %Mod{
                    default_price: 60,
                    min_price: 50,
                    id: "56dac8cc5cc639de0a45c52c",
                    name: "Energy Conversion"
                  },
                  %Mod{
                    default_price: 60,
                    min_price: 50,
                    id: "56dac8d25cc639de0a45c52d",
                    name: "Health Conversion"
                  },
                  %ModWithoutRank{
                    default_price: 60,
                    id: "588a789c3cf52c408a2f88dc",
                    min_price: 50,
                    name: "Astral Autopsy"
                  },
                  %Arcane{
                    default_price: 3,
                    id: "675c5edc7b18977f6e6453f4",
                    min_price: 2,
                    name: "Arcane Bellicose",
                    quantity: 17
                  },
                  %Arcane{
                    default_price: 3,
                    id: "675c5ed17b18977f6e6453f2",
                    min_price: 2,
                    name: "Arcane Camisado",
                    quantity: 17
                  },
                  %Arcane{
                    default_price: 3,
                    id: "675c59247b18977f6e6453e8",
                    min_price: 2,
                    name: "Arcane Crepuscular",
                    quantity: 17
                  },
                  %Arcane{
                    default_price: 3,
                    id: "675c59297b18977f6e6453ea",
                    min_price: 2,
                    name: "Arcane Impetus",
                    quantity: 17
                  },
                  %Arcane{
                    default_price: 3,
                    id: "675c5ee47b18977f6e6453f6",
                    min_price: 2,
                    name: "Arcane Truculence",
                    quantity: 17
                  },
                  %Arcane{
                    default_price: 3,
                    id: "675c5cd97b18977f6e6453f0",
                    min_price: 2,
                    name: "Melee Doughty",
                    quantity: 17
                  },
                  %Arcane{
                    default_price: 3,
                    id: "675c59347b18977f6e6453ec",
                    min_price: 2,
                    name: "Primary Crux",
                    quantity: 17
                  },
                  %Arcane{
                    default_price: 3,
                    id: "675c5cd07b18977f6e6453ee",
                    min_price: 2,
                    name: "Secondary Enervate",
                    quantity: 17
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
         %Mod{
           name: "Looter",
           id: "5740c1879d238d4a03d28518",
           min_price: 50,
           default_price: 60
         }}

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
      user = User.new(%{"ingame_name" => "Ph03n1x", "slug" => "ph03n1x", "patreon?" => true})

      # Act & Assert
      assert Store.save_login_data(auth, user) == :ok

      {:ok, content} = File.read(@setup_file)

      assert Jason.decode!(content) ==
               %{
                 "user" => %{"ingame_name" => "Ph03n1x", "slug" => "ph03n1x", "patreon?" => true},
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
      user = User.new(%{"ingame_name" => "Fl4m3", "slug" => "fl4m3", "patreon?" => false})

      # Act & Assert
      assert Store.get_login_data() == {:ok, {auth, user}}
    end
  end

  describe "list_syndicates/0" do
    test "returns list of all syndicates" do
      {:ok, syndicates} = Store.list_syndicates()

      expected_ids =
        MapSet.new([
          :arbiters_of_hexis,
          :arbitrations,
          :cephalon_simaris,
          :cephalon_suda,
          :new_loka,
          :perrin_sequence,
          :red_veil,
          :steel_meridian,
          :the_hex,
          :the_quills,
          :the_zariman,
          :conjunction_survival
        ])

      actual_ids = MapSet.new(Enum.map(syndicates, & &1.id))

      assert MapSet.equal?(actual_ids, expected_ids)
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
