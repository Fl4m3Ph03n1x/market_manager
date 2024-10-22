defmodule StoreTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Shared.Data.{Authorization, Product, Syndicate, User}
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

  describe "activate_syndicates/2" do
    setup do
      create_watch_list_file()
      on_exit(&reset_watch_list_file/0)
    end

    test "marks the given syndicates as active with the given strategy" do
      # Act & Assert
      assert Store.activate_syndicates([:new_loka, :red_veil], :top_five_average) == :ok

      assert Store.list_active_syndicates() ==
               {:ok,
                %{
                  new_loka: :top_five_average,
                  red_veil: :top_five_average,
                  cephalon_suda: :lowest_minus_one,
                  cephalon_simaris: :equal_to_lowest
                }}
    end

    test "overwrites strategy for the given syndicate if it is already active" do
      # Act & Assert

      assert Store.activate_syndicates([:new_loka, :cephalon_suda], :top_five_average) == :ok
      assert Store.activate_syndicates([:new_loka], :top_three_average) == :ok

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
