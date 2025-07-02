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
          operation_in_progress?: false,
          selected_button: :activate,
          message: nil
        )

      {:ok, updated_socket}
    else
      error ->
        Logger.error("Unable to show deactivation page: #{inspect(error)}")
        {:error, put_flash(socket, :error, "Unable to show deactivation page!")}
    end
  end

  ###################
  # Frontend Events #
  ###################

  @impl true
  def handle_event("execute", %{"strategy" => strategy_id, "syndicates" => syndicate_ids}, socket) do
    params =
      Enum.reduce(syndicate_ids, %{}, fn syn_id, acc ->
        Map.put(acc, String.to_atom(syn_id), String.to_atom(strategy_id))
      end)

    with {:ok, strategy} <- StrategyStore.get_strategy_by_id(strategy_id),
         {:ok, syndicates} <- SyndicateStore.get_all_syndicates_by_id(syndicate_ids),
         :ok <- Manager.activate(params) do
      updated_socket =
        socket
        |> assign(selected_strategy: strategy)
        |> assign(selected_active_syndicates: syndicates)
        |> assign(activation_in_progress: true)
        |> assign(operation_in_progress?: true)
        |> assign(activation_progress: 0)
        |> assign(message: "Activation in progress...")

      {:noreply, updated_socket}
    else
      err ->
        Logger.error("Unable to retrieve data: #{inspect(err)}")
        {:noreply, put_flash(socket, :error, "Unable to retrieve data!")}
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
        {:noreply, put_flash(socket, :error, "Unable to retrieve data!")}
    end
  end

  def handle_event("change", %{"strategy" => strategy_id}, socket) do
    with {:ok, strategy} <- StrategyStore.get_strategy_by_id(strategy_id),
         :ok <- StrategyStore.set_selected_strategy(strategy) do
      {:noreply, assign(socket, selected_strategy: strategy)}
    else
      err ->
        Logger.error("Unable to retrieve strategy data: #{inspect(err)}")
        {:noreply, put_flash(socket, :error, "Unable to retrieve data!")}
    end
  end

  def handle_event(
        "change",
        %{"syndicates" => syndicate_ids, "strategies" => strategy_id},
        socket
      ) do
    with {:ok, strategy} <- StrategyStore.get_strategy_by_id(strategy_id),
         {:ok, syndicates} <- SyndicateStore.get_all_syndicates_by_id(syndicate_ids),
         :ok <- StrategyStore.set_selected_strategy(strategy),
         {:ok, active_syndicates} <- SyndicateStore.get_active_syndicates(),
         new_selected_syndicates = Enum.uniq(syndicates ++ active_syndicates),
         :ok <- SyndicateStore.set_selected_active_syndicates(new_selected_syndicates) do
      {:noreply,
       assign(socket,
         selected_strategy: strategy,
         selected_active_syndicates: new_selected_syndicates
       )}
    else
      err ->
        Logger.error("Unable to retrieve change data: #{inspect(err)}")
        {:noreply, put_flash(socket, :error, "Unable to retrieve data!")}
    end
  end

  def handle_event(event, params, socket) do
    Logger.error("Event: #{inspect(event)} ; #{inspect(params)}")
    {:noreply, socket}
  end

  ##################
  # Backend Events #
  ##################

  @impl true
  def handle_info({:activate, {:ok, :get_user_orders}}, socket) do
    Logger.info("Activate: Getting user orders.")
    {:noreply, assign(socket, message: "Activate: Getting user orders.")}
  end

  def handle_info({:activate, {:ok, :calculating_item_prices}}, socket) do
    Logger.info("Activate: Calculating item prices.")
    {:noreply, assign(socket, message: "Activate: Calculating item prices.")}
  end

  def handle_info({:activate, {:ok, {:price_calculated, item_name, price, current_progress, total_progress}}}, socket) do
    progress = round(current_progress / total_progress * 100)

    Logger.info("Activate: Price calculated for #{item_name}, #{price}p, #{progress}%")
    {:noreply, assign(socket, activation_progress: progress)}
  end

  def handle_info({:activate, {:ok, :placing_orders}}, socket) do
    Logger.info("Activate: Placing orders.")
    {:noreply, assign(socket, message: "Activate: Placing orders.")}
  end

  def handle_info({:activate, {:ok, {:order_placed, item_name, current_progress, total_progress}}}, socket) do
    progress = round(current_progress / total_progress * 100)

    Logger.info("Activate: Order placed for #{item_name}, #{progress}%")
    {:noreply, assign(socket, activation_progress: progress)}
  end

  def handle_info({:activate, {:ok, :done}}, socket) do
    with {:ok, selected_syndicates} <- SyndicateStore.get_selected_active_syndicates(),
         :ok <- SyndicateStore.activate_syndicates(selected_syndicates),
         {:ok, all_syndicates_active?} <- SyndicateStore.all_syndicates_active?(),
         {:ok, active_syndicates} <- SyndicateStore.get_active_syndicates() do
      updated_socket =
        socket
        |> assign(active_syndicates: active_syndicates)
        |> assign(all_syndicates_active?: all_syndicates_active?)
        |> assign(activation_in_progress: false)
        |> assign(operation_in_progress?: false)
        |> assign(message: nil)

      Logger.info("Activate: Action completed.")
      {:noreply, updated_socket}
    else
      error ->
        Logger.error("Unable complete syndicate activation: #{inspect(error)}")
        {:noreply, put_flash(socket, :error, "Unable complete syndicate activation!")}
    end
  end

  def handle_info(message, socket) do
    Logger.error("Unknown message received: #{inspect(message)}")

    {:noreply, put_flash(socket, :error, "Something unexpected happened, please report it!")}
  end

  ####################
  # Helper Functions #
  ####################

  @spec disable_button?(Strategy.t() | nil, [Syndicate.t()], [Syndicate.t()]) :: boolean
  def disable_button?(strategy, selected_syndicates, active_syndicates),
    do:
      is_nil(strategy) or Enum.empty?(selected_syndicates) or
        Enum.sort(selected_syndicates) == Enum.sort(active_syndicates)
end
