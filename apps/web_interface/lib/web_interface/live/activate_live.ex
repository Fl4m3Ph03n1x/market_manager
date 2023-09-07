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
        active_syndicates: active_syndicates,
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
          {:ok, [syndicate | _rest] = syndicates} <- Persistence.get_all_syndicates_by_id(syndicate_ids) do

          :ok = Manager.activate(Atom.to_string(syndicate.id), strategy.id)

          updated_socket =
            socket
            |> assign(selected_strategy: strategy)
            |> assign(selected_syndicates: syndicates)
            |> assign(activation_in_progress: true)
            |> assign(activation_current_syndicate: syndicate)
            |> assign(activation_progress: 0)

          {:noreply, updated_socket}
    else
      err ->
        Logger.error("Unable to retrieve data: #{inspect(err)}")
        {:noreply, socket |> put_flash(:error, "Unable to retrieve data!")}
    end
  end

  def handle_event("change", %{"_target" => ["syndicates"]} = change_data, socket) do
    syndicate_ids = Map.get(change_data, "syndicates", [])

    with  {:ok, syndicates} <- Persistence.get_all_syndicates_by_id(syndicate_ids),
          :ok <- Persistence.set_selected_syndicates(syndicates) do
      {:noreply, assign(socket, selected_syndicates: syndicates)}
    else
      err ->
        Logger.error("Unable to retrieve syndicate data: #{inspect(err)}")
        {:noreply, socket |> put_flash(:error, "Unable to retrieve data!")}
    end
  end

  def handle_event("change", %{"strategy" => strategy_id}, socket) do
    with  {:ok, strategy} <- Persistence.get_strategy_by_id(strategy_id),
          :ok <- Persistence.set_selected_strategy(strategy) do
      {:noreply, assign(socket, selected_strategy: strategy)}
    else
      err ->
        Logger.error("Unable to retrieve strategy data: #{inspect(err)}")
        {:noreply, socket |> put_flash(:error, "Unable to retrieve data!")}
    end
  end

  def handle_event("change", %{"syndicates" => syndicate_ids, "strategies" => strategy_id}, socket) do

    with  {:ok, strategy} <- Persistence.get_strategy_by_id(strategy_id),
          {:ok, syndicates} <- Persistence.get_all_syndicates_by_id(syndicate_ids),
          :ok <- Persistence.set_selected_strategy(strategy),
          :ok <- Persistence.set_selected_syndicates(syndicates) do
      {:noreply, assign(socket, selected_strategy: strategy, selected_syndicates: syndicates)}
    else
      err ->
        Logger.error("Unable to retrieve change data: #{inspect(err)}")
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

  def handle_info({:activate, syndicate_id_str, :done} = mess, socket) do
    Logger.info("Activation of #{syndicate_id_str} complete.")

    with {:ok, syndicate} <- Persistence.get_syndicate_by_id(syndicate_id_str),
      {:ok, strategy} <- Persistence.get_selected_strategy(),
      :ok <- Persistence.activate_syndicate(syndicate),
      {:ok, all_syndicates_active?} <- Persistence.all_syndicates_active?(),
      {:ok, selected_syndicates} <- Persistence.get_selected_syndicates(),
      {:ok, active_syndicates} <- Persistence.get_active_syndicates(),
      {:ok, syndicates} <- Persistence.get_syndicates() do

        missing_syndicates =
          selected_syndicates
          |> MapSet.new()
          |> MapSet.difference(MapSet.new(active_syndicates))
          |> MapSet.to_list()

        to_assign =
          if Enum.empty?(missing_syndicates) do
            [activation_current_syndicate: nil, activation_in_progress: false]
          else
            [next_syndicate | _rest] = missing_syndicates
            :ok = Manager.activate(Atom.to_string(next_syndicate.id), strategy.id)
            [activation_current_syndicate: next_syndicate, activation_progress: 0]
          end

        updated_socket =
          socket
          |> assign(active_syndicates: active_syndicates)
          |> assign(inactive_syndicates: syndicates -- active_syndicates)
          |> assign(all_syndicates_active?: all_syndicates_active?)
          |> assign(to_assign)

        {:noreply, updated_socket}
      else
        error ->
          Logger.error("Unable complete syndicate activation: #{inspect(error)}")
          {:noreply, socket |> put_flash(:error, "Unable complete syndicate activation!")}
      end
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
