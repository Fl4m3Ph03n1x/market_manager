defmodule WebInterface.ActivateLive do
  use WebInterface, :live_view

  require Logger

  alias Manager
  alias Shared.Data.{Strategy, Syndicate}
  alias WebInterface.Persistence.Strategy, as: StrategyStore
  alias WebInterface.Persistence.Syndicate, as: SyndicateStore
  alias WebInterface.Persistence.User, as: UserStore

  @impl true
  def mount(_params, _session, socket) do
    with {:ok, user} <- UserStore.get_user(),
         {:ok, syndicates} <- SyndicateStore.get_syndicates(),
         {:ok, strategies} <- StrategyStore.get_strategies(),
         {:ok, active_syndicates} <- SyndicateStore.get_active_syndicates(),
         {:ok, selected_strategy} <- StrategyStore.get_selected_strategy(),
         {:ok, selected_active_syndicates} <- SyndicateStore.get_selected_active_syndicates() do
      updated_socket =
        assign(
          socket,
          user: user,
          syndicates: syndicates,
          strategies: strategies,
          active_syndicates: active_syndicates,
          selected_strategy: selected_strategy,
          selected_active_syndicates: selected_active_syndicates,
          form: to_form(%{"activate_syndicates" => []}),
          activation_in_progress: false,
          activation_progress: 0,
          activation_current_syndicate: nil,
          operation_in_progress?: false,
          selected_button: :activate
        )

      {:ok, updated_socket}
    else
      error ->
        Logger.error("Unable to show deactivation page: #{inspect(error)}")
        {:error, socket |> put_flash(:error, "Unable to show deactivation page!")}
    end
  end

  @impl true
  def handle_event("execute", %{"strategy" => strategy_id, "syndicates" => syndicate_ids}, socket) do
    with {:ok, strategy} <- StrategyStore.get_strategy_by_id(strategy_id),
         {:ok, [syndicate | _rest] = syndicates} <- SyndicateStore.get_all_syndicates_by_id(syndicate_ids),
         :ok <- Manager.activate(syndicate, strategy) do
      updated_socket =
        socket
        |> assign(selected_strategy: strategy)
        |> assign(selected_active_syndicates: syndicates)
        |> assign(activation_in_progress: true)
        |> assign(operation_in_progress?: true)
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

    with {:ok, syndicates} <- SyndicateStore.get_all_syndicates_by_id(syndicate_ids),
         {:ok, active_syndicates} <- SyndicateStore.get_active_syndicates(),
         new_selected_syndicates = Enum.uniq(syndicates ++ active_syndicates),
         :ok <- SyndicateStore.set_selected_active_syndicates(new_selected_syndicates) do
      {:noreply, assign(socket, selected_active_syndicates: new_selected_syndicates)}
    else
      err ->
        Logger.error("Unable to retrieve syndicate data: #{inspect(err)}")
        {:noreply, socket |> put_flash(:error, "Unable to retrieve data!")}
    end
  end

  def handle_event("change", %{"strategy" => strategy_id}, socket) do
    with {:ok, strategy} <- StrategyStore.get_strategy_by_id(strategy_id),
         :ok <- StrategyStore.set_selected_strategy(strategy) do
      {:noreply, assign(socket, selected_strategy: strategy)}
    else
      err ->
        Logger.error("Unable to retrieve strategy data: #{inspect(err)}")
        {:noreply, socket |> put_flash(:error, "Unable to retrieve data!")}
    end
  end

  def handle_event(
        "change",
        %{"syndicates" => syndicate_ids, "strategies" => strategy_id},
        socket
      ) do
    with {:ok, strategy} <- StrategyStore.get_strategy_by_id(strategy_id),
         {:ok, syndicates} <-
           SyndicateStore.get_all_syndicates_by_id(syndicate_ids),
         :ok <- StrategyStore.set_selected_strategy(strategy),
         {:ok, active_syndicates} <- SyndicateStore.get_active_syndicates(),
         new_selected_syndicates =
           Enum.uniq(syndicates ++ active_syndicates),
         :ok <- SyndicateStore.set_selected_active_syndicates(new_selected_syndicates) do
      {:noreply,
       assign(socket,
         selected_strategy: strategy,
         selected_active_syndicates: new_selected_syndicates
       )}
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
  def handle_info({:activate, syndicate, {:error, reason} = error}, socket) do
    Logger.error("Unable to activate syndicate #{syndicate.name}: #{inspect(error)}")

    with {:ok, active_syndicates} <- SyndicateStore.get_active_syndicates(),
         new_selected_syndicates = active_syndicates -- [syndicate],
         :ok <- SyndicateStore.set_selected_active_syndicates(new_selected_syndicates) do
      {:noreply,
       put_flash(
         assign(socket, operation_in_progress?: false),
         :error,
         "Unable to activate syndicate #{syndicate.name} due to '#{reason}'."
       )}
    else
      err ->
        Logger.error("Failed to retrieve persistence data: #{inspect(err)}")

        {:noreply, put_flash(socket, :error, "Multiple errors ocurred, please check the logs.")}
    end
  end

  def handle_info(
        {:activate, syndicate, {current_item, total_items, {:error, reason, _item} = error}},
        socket
      ) do
    Logger.error("Order placement for item of #{syndicate.name} failed: #{inspect(error)}")

    updated_socket =
      socket
      |> assign(activation_progress: round(current_item / total_items * 100))
      |> put_flash(:error, "Unable to place an order for #{syndicate.name} due to '#{reason}'.")

    {:noreply, updated_socket}
  end

  def handle_info(
        {:activate, syndicate, {current_item, total_items, {:ok, %Shared.Data.PlacedOrder{item_id: item_id}}}},
        socket
      ) do
    Logger.info("Order placed for #{syndicate.name}: #{item_id}")

    {:noreply, assign(socket, activation_progress: round(current_item / total_items * 100))}
  end

  def handle_info({:activate, syndicate, :done}, socket) do
    Logger.info("Activation of #{syndicate.name} complete.")

    with {:ok, strategy} <- StrategyStore.get_selected_strategy(),
         :ok <- SyndicateStore.activate_syndicate(syndicate),
         {:ok, all_syndicates_active?} <- SyndicateStore.all_syndicates_active?(),
         {:ok, selected_syndicates} <- SyndicateStore.get_selected_active_syndicates(),
         {:ok, active_syndicates} <- SyndicateStore.get_active_syndicates(),
         new_selected_syndicates =
           Enum.uniq(selected_syndicates ++ active_syndicates),
         :ok <- SyndicateStore.set_selected_active_syndicates(new_selected_syndicates) do
      missing_syndicates =
        selected_syndicates
        |> MapSet.new()
        |> MapSet.difference(MapSet.new(active_syndicates))
        |> MapSet.to_list()
        |> List.flatten()

      to_assign =
        if Enum.empty?(missing_syndicates) do
          [activation_current_syndicate: nil, activation_in_progress: false, operation_in_progress?: false]
        else
          [next_syndicate | _rest] = missing_syndicates
          :ok = Manager.activate(next_syndicate, strategy)
          [activation_current_syndicate: next_syndicate, activation_progress: 0]
        end

      updated_socket =
        socket
        |> assign(active_syndicates: active_syndicates)
        |> assign(all_syndicates_active?: all_syndicates_active?)
        |> assign(selected_active_syndicates: new_selected_syndicates)
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

  @spec disable_button?(Strategy.t() | nil, [Syndicate.t()], [Syndicate.t()]) :: boolean
  def disable_button?(strategy, selected_syndicates, active_syndicates),
    do:
      is_nil(strategy) or Enum.empty?(selected_syndicates) or
        Enum.sort(selected_syndicates) == Enum.sort(active_syndicates)

  @spec progress_bar_message(Syndicate.t() | nil) :: String.t()
  def progress_bar_message(nil), do: "Operation in progress ..."

  def progress_bar_message(activation_current_syndicate),
    do: "Activation for #{activation_current_syndicate.name} in progress ..."
end
