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
    {:ok, selected_strategy} = Persistence.get_selected_strategy()
    {:ok, selected_syndicates} = Persistence.get_selected_syndicates()

    updated_socket =
      assign(
        socket,
        user: user,
        all_syndicates_active?: all_active,
        syndicates: syndicates,
        strategies: strategies,
        inactive_syndicates: syndicates -- active_syndicates,
        selected_strategy: selected_strategy,
        selected_syndicates: selected_syndicates,
        form: to_form(%{"activate_syndicates" => []}),
        activation_in_progress: false,
        activation_progress: 0,
        activation_current_syndicate: nil
      )

    {:ok, updated_socket}
  end

  @impl true
  def handle_event("execute", %{"strategy" => strategy_id, "syndicates" => syndicate_ids}, socket) do
    with  {:ok, strategy} <- Persistence.get_strategy_by_id(strategy_id),
          {:ok, syndicates} <- Persistence.get_all_syndicates_by_id(syndicate_ids) do

          for syndicate <- syndicates do
            :ok = Manager.activate(Atom.to_string(syndicate.id), strategy.id)
          end

          updated_socket =
            socket
            |> assign(selected_strategy: strategy)
            |> assign(selected_syndicates: syndicates)
            |> assign(activation_in_progress: true)
            |> assign(activation_progress: 0)

          {:noreply, updated_socket}
    else
      err ->
        Logger.error("Unable to retrieve data: #{inspect(err)}")
        {:noreply, socket |> put_flash(:error, "Unable to retrieve data!")}
    end
  end

  def handle_event("change", params, socket) do

    strategy_id = Map.get(params, "strategy", "")
    syndicate_ids = Map.get(params, "syndicates", [])

    with  {:ok, strategy} <- Persistence.get_strategy_by_id(strategy_id),
          {:ok, syndicates} <- Persistence.get_all_syndicates_by_id(syndicate_ids),
          :ok <- Persistence.set_selected_strategy(strategy),
          :ok <- Persistence.set_selected_syndicates(syndicates) do
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
  def handle_info({:activate, syndicate_name, {:error, reason} = error}, socket) do
    Logger.error("Unable to activate syndicate #{syndicate_name}: #{inspect(error)}")

    {:noreply, put_flash(socket, :error, "Unable to activate syndicate #{syndicate_name} due to '#{reason}'.")}
  end

  def handle_info({:activate, syndicate, {current_item, total_items, {:error, reason, _item} = error}}, socket) do
    Logger.error("Order placement for item of #{syndicate} failed: #{inspect(error)}")

    updated_socket =
      socket
      |> assign(activation_progress: round((current_item / total_items) * 100))
      |> put_flash(:error, "Unable to place an order for #{syndicate} due to '#{reason}'.")

    {:noreply, updated_socket}
  end

  def handle_info({:activate, syndicate, {current_item, total_items, {:ok, %Shared.Data.PlacedOrder{item_id: item_id}}}}, socket) do
    Logger.info("Order placed for #{syndicate}: #{item_id}")

    {:noreply, assign(socket, activation_progress: round((current_item / total_items) * 100))}
  end

  def handle_info({:activate, syndicate_name, :done}, socket) do
    Logger.info("Activation of #{syndicate_name} complete.")

    updated_socket =
      socket
      |> assign(activation_current_syndicate: nil)
      |> assign(activation_in_progress: false)

    {:noreply, updated_socket}
  end

  def handle_info(message, socket) do
    Logger.error("Unknown message received: #{inspect(message)}")

    {:noreply, socket |> put_flash(:error, "Something unexpected happened, please report it!")}
  end

  ####################
  # Helper Functions #
  ####################

  @spec disable_button?(Strategy.t() | nil, [Syndicates.t()] ) :: boolean
  def disable_button?(strategy, syndicates), do: is_nil(strategy) or Enum.empty?(syndicates)

end
