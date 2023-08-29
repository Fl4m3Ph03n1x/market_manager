defmodule WebInterface.ActivateLive do
  use WebInterface, :live_view

  require Logger

  alias Manager
  alias WebInterface.Persistence

  @impl true
  def mount(_params, _session, socket) do
    {:ok, user} = Persistence.get_user()
    {:ok, syndicates} = Persistence.get_syndicates()
    {:ok, strategies} = Persistence.get_strategies()
    {:ok, all_active} = Persistence.all_syndicates_active?()
    {:ok, active_syndicates} =  Persistence.get_active_syndicates()

    updated_socket =
      assign(
        socket,
        user: user,
        all_syndicates_active?: all_active,
        syndicates: syndicates,
        strategies: strategies,
        inactive_syndicates: syndicates -- active_syndicates,
        selected_strategy: nil,
        selected_syndicates: [],
        form: to_form(%{"genres" => []})
      )

    {:ok, updated_socket}
  end

  @spec syndicates_to_string([Syndicate.t()]) :: String.t()
  defp syndicates_to_string(syndicates), do: Enum.map_join(syndicates, ";", fn syn -> syn.id end)

  @impl true
  def handle_event("activate-filters", %{"strategy" => strategy_id, "syndicates" => syndicate_ids} = params, socket) do

    with  {:ok, strategy} <- Persistence.get_strategy_by_id(strategy_id),
          {:ok, syndicates} <- Persistence.get_all_syndicates_by_id(syndicate_ids) do

          Logger.info("STRATEGY: #{inspect(strategy)}")
          Logger.info("SYNDICATES: #{inspect(syndicates)}")
          Logger.info("INACTIVE SYNDS: #{inspect(@inactive_syndicates)}")
      {:noreply, assign(socket, selected_strategy: strategy, selected_syndicates: syndicates)}
    else
      err ->
        Logger.error("Unable to retrieve data: #{inspect(err)}")
        {:noreply, socket |> put_flash(:error, "Unable to retrieve data!")}
    end

  end

  def handle_event(event, params, socket) do
    Logger.info("Event: #{inspect(event)} ; #{inspect(params)}")
    {:noreply, socket}
  end

  @impl true
  def handle_info(message, socket) do
    Logger.error("Unknown message received: #{inspect(message)}")

    {:noreply, socket |> put_flash(:error, "Something unexpected happened, please report it!")}
  end
end
