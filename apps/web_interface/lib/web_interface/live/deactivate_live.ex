defmodule WebInterface.DeactivateLive do
  use WebInterface, :live_view

  require Logger

  alias Manager
  alias Shared.Data.Syndicate
  alias WebInterface.Persistence.Syndicate, as: SyndicateStore
  alias WebInterface.Persistence.User, as: UserStore

  @impl true
  def mount(_params, _session, socket) do
    with {:ok, user} <- UserStore.get_user(),
         {:ok, syndicates} <- SyndicateStore.get_syndicates(),
         {:ok, inactive_syndicates} <- SyndicateStore.get_inactive_syndicates(),
         {:ok, selected_inactive_syndicates} <- SyndicateStore.get_selected_inactive_syndicates() do
      updated_socket =
        assign(
          socket,
          user: user,
          syndicates: syndicates,
          inactive_syndicates: inactive_syndicates,
          selected_inactive_syndicates: selected_inactive_syndicates,
          form: to_form(%{"deactivate_syndicates" => []}),
          deactivation_in_progress: false,
          deactivation_progress: 0,
          operation_in_progress?: false,
          selected_button: :deactivate,
          message: nil
        )

      {:ok, updated_socket}
    else
      error ->
        Logger.error("Unable to show deactivation page: #{inspect(error)}")
        {:error, socket |> put_flash(:error, "Unable to show deactivation page!")}
    end
  end

  ###################
  # Frontend Events #
  ###################

  @impl true
  def handle_event("execute", %{"syndicates" => syndicate_ids}, socket) do
    syndicate_atom_ids = Enum.map(syndicate_ids, &String.to_atom/1)

    with {:ok, syndicates} <- SyndicateStore.get_all_syndicates_by_id(syndicate_ids),
         :ok <- Manager.deactivate(syndicate_atom_ids) do
      updated_socket =
        socket
        |> assign(selected_inactive_syndicates: syndicates)
        |> assign(deactivation_in_progress: true)
        |> assign(operation_in_progress?: true)
        |> assign(deactivation_progress: 0)

      {:noreply, updated_socket}
    else
      err ->
        Logger.error("Unable to retrieve data: #{inspect(err)}")
        {:noreply, put_flash(socket, :error, "Unable to retrieve data!")}
    end
  end

  def handle_event("change", %{"syndicates" => syndicate_ids}, socket) do
    with {:ok, syndicates} <- SyndicateStore.get_all_syndicates_by_id(syndicate_ids),
         {:ok, inactive_syndicates} <- SyndicateStore.get_inactive_syndicates(),
         new_selected_syndicates =
           Enum.uniq(syndicates ++ inactive_syndicates),
         :ok <- SyndicateStore.set_selected_inactive_syndicates(new_selected_syndicates) do
      {:noreply, assign(socket, selected_inactive_syndicates: new_selected_syndicates)}
    else
      err ->
        Logger.error("Unable to retrieve change data: #{inspect(err)}")
        {:noreply, put_flash(socket, :error, "Unable to retrieve data!")}
    end
  end

  def handle_event("change", _no_syndicates_selected, socket) do
    with {:ok, inactive_syndicates} <- SyndicateStore.get_inactive_syndicates(),
         :ok <- SyndicateStore.set_selected_inactive_syndicates(inactive_syndicates) do
      {:noreply, assign(socket, selected_inactive_syndicates: inactive_syndicates)}
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
  def handle_info({:deactivate, {:ok, :get_user_orders}}, socket) do
    Logger.info("Deactivate: Getting user orders.")
    {:noreply, assign(socket, message: "Deactivate: Getting user orders.")}
  end

  def handle_info({:deactivate, {:ok, :deleting_orders}}, socket) do
    Logger.info("Deactivate: Deleting orders.")
    {:noreply, assign(socket, message: "Deactivate: Deleting orders.")}
  end

  def handle_info(
        {:deactivate, {:ok, {:order_deleted, item_name, current_progress, total_progress}}},
        socket
      ) do
    progress = round(current_progress / total_progress * 100)

    Logger.info("Deactivate: Order deleted for #{item_name}, #{progress}%")
    {:noreply, assign(socket, deactivation_progress: progress)}
  end

  def handle_info({:deactivate, {:ok, :done}}, socket) do
    with {:ok, selected_syndicates} <- SyndicateStore.get_selected_inactive_syndicates(),
         :ok <- SyndicateStore.deactivate_syndicates(selected_syndicates),
         {:ok, inactive_syndicates} <- SyndicateStore.get_inactive_syndicates(),
         new_inactive_syndicates = Enum.uniq(selected_syndicates ++ inactive_syndicates),
         :ok <- SyndicateStore.set_selected_inactive_syndicates(new_inactive_syndicates) do
      updated_socket =
        socket
        |> assign(inactive_syndicates: inactive_syndicates)
        |> assign(selected_inactive_syndicates: new_inactive_syndicates)
        |> assign(deactivation_in_progress: false)
        |> assign(operation_in_progress?: false)
        |> assign(message: nil)

      Logger.info("Deactivate: Action completed.")
      {:noreply, updated_socket}
    else
      error ->
        Logger.error("Unable complete syndicate deactivation: #{inspect(error)}")
        {:noreply, put_flash(socket, :error, "Unable complete syndicate deactivation!")}
    end
  end

  def handle_info({:deactivate, {:ok, :reactivating_remaining_syndicates}}, socket) do
    updated_socket =
      socket
      |> assign(message: "Deactivate: Action completed, recalculating remaining syndicates.")

    Logger.info("Deactivate: Recalculating prices for items of other syndicates.")
    {:noreply, updated_socket}
  end

  def handle_info({:activate, {:ok, :get_user_orders}}, socket) do
    Logger.info("Deactivate: Getting remaining user orders.")
    {:noreply, assign(socket, message: "Deactivate: Getting remaining user orders.")}
  end

  def handle_info({:activate, {:ok, :calculating_item_prices}}, socket) do
    Logger.info("Deactivate: Recalculating item prices.")
    {:noreply, assign(socket, message: "Deactivate: Recalculating item prices.")}
  end

  def handle_info({:activate, {:ok, {:price_calculated, item_name, price, current_progress, total_progress}}}, socket) do
    progress = round(current_progress / total_progress * 100)

    Logger.info("Deactivate: Price recalculated for #{item_name}, #{price}p, #{progress}%")
    {:noreply, assign(socket, deactivation_progress: progress)}
  end

  def handle_info({:activate, {:ok, :placing_orders}}, socket) do
    Logger.info("Deactivate: Placing updated orders.")
    {:noreply, assign(socket, message: "Deactivate: Placing updated orders.")}
  end

  def handle_info({:activate, {:ok, {:order_placed, item_name, current_progress, total_progress}}}, socket) do
    progress = round(current_progress / total_progress * 100)

    Logger.info("Deactivate: Order placed for #{item_name}, #{progress}%")
    {:noreply, assign(socket, deactivation_progress: progress)}
  end

  def handle_info({:activate, {:ok, :done}}, socket) do
    with {:ok, selected_syndicates} <- SyndicateStore.get_selected_inactive_syndicates(),
         :ok <- SyndicateStore.deactivate_syndicates(selected_syndicates),
         {:ok, inactive_syndicates} <- SyndicateStore.get_inactive_syndicates(),
         new_inactive_syndicates = Enum.uniq(selected_syndicates ++ inactive_syndicates),
         :ok <- SyndicateStore.set_selected_inactive_syndicates(new_inactive_syndicates) do
      updated_socket =
        socket
        |> assign(inactive_syndicates: inactive_syndicates)
        |> assign(selected_inactive_syndicates: new_inactive_syndicates)
        |> assign(deactivation_in_progress: false)
        |> assign(operation_in_progress?: false)
        |> assign(message: nil)

      Logger.info("Deactivate: Action completed.")
      {:noreply, updated_socket}
    else
      error ->
        Logger.error("Unable complete syndicate deactivation: #{inspect(error)}")
        {:noreply, put_flash(socket, :error, "Unable complete syndicate deactivation!")}
    end
  end

  def handle_info(message, socket) do
    Logger.error("Unknown message received: #{inspect(message)}")

    {:noreply, put_flash(socket, :error, "Something unexpected happened, please report it!")}
  end

  # def handle_info({:deactivate, syndicate, {:error, reason} = error}, socket) do
  #   Logger.error("Unable to deactivate syndicate #{syndicate.name}: #{inspect(error)}")

  #   with {:ok, inactive_syndicates} <- SyndicateStore.get_inactive_syndicates(),
  #        new_selected_syndicates = inactive_syndicates -- [syndicate],
  #        :ok <- SyndicateStore.set_selected_inactive_syndicates(new_selected_syndicates) do
  #     {:noreply,
  #      put_flash(
  #        assign(socket, operation_in_progress?: true),
  #        :error,
  #        "Unable to deactivate syndicate #{syndicate.name} due to '#{reason}'."
  #      )}
  #   else
  #     err ->
  #       Logger.error("Failed to retrieve persistence data: #{inspect(err)}")

  #       {:noreply, put_flash(socket, :error, "Multiple errors ocurred, please check the logs.")}
  #   end
  # end

  # def handle_info(
  #       {:deactivate, syndicate, {current_item, total_items, {:error, reason, _item} = error}},
  #       socket
  #     ) do
  #   Logger.error("Order deletion for item of #{syndicate.name} failed: #{inspect(error)}")

  #   updated_socket =
  #     socket
  #     |> assign(deactivation_progress: round(current_item / total_items * 100))
  #     |> put_flash(:error, "Unable to delete an order for #{syndicate.name} due to '#{reason}'.")

  #   {:noreply, updated_socket}
  # end

  # def handle_info(
  #       {:deactivate, syndicate, {current_item, total_items, {:ok, %Shared.Data.PlacedOrder{item_id: item_id}}}},
  #       socket
  #     ) do
  #   Logger.info("Order deleted for #{syndicate.name}: #{item_id}")

  #   {:noreply, assign(socket, deactivation_progress: round(current_item / total_items * 100))}
  # end

  # def handle_info({:deactivate, syndicate, :done}, socket) do
  #   Logger.info("Deactivation of #{syndicate.name} complete.")

  #   with {:ok, selected_syndicates} <- SyndicateStore.get_selected_inactive_syndicates(),
  #        {:ok, inactive_syndicates} <- SyndicateStore.get_inactive_syndicates(),
  #        {:ok, active_syndicates} <- Manager.active_syndicates(),
  #        new_selected_syndicates =
  #          Enum.uniq(selected_syndicates ++ inactive_syndicates),
  #        :ok <- SyndicateStore.set_selected_inactive_syndicates(new_selected_syndicates) do
  #     missing_syndicates =
  #       selected_syndicates
  #       |> MapSet.new()
  #       |> MapSet.difference(MapSet.new(inactive_syndicates))
  #       |> MapSet.to_list()
  #       |> List.flatten()

  #     to_assign =
  #       if Enum.empty?(missing_syndicates) do
  #         [deactivation_current_syndicate: nil, deactivation_in_progress: false, operation_in_progress?: false]
  #       else
  #         [next_syndicate | _rest] = missing_syndicates
  #         :ok = Manager.deactivate(next_syndicate)
  #         [deactivation_current_syndicate: next_syndicate, deactivation_progress: 0]
  #       end

  #     updated_socket =
  #       socket
  #       |> assign(inactive_syndicates: inactive_syndicates)
  #       |> assign(selected_inactive_syndicates: new_selected_syndicates)
  #       |> assign(to_assign)

  #     # specially common in the case of timeouts from the auction house
  #     partial_deactivation? =
  #       Enum.find(active_syndicates, fn syn -> syn.id == syndicate.id end) != nil

  #     updated_socket =
  #       if partial_deactivation? do
  #         Logger.info("Syndicate #{syndicate.name} was only partially deactivated. Try again later!")

  #         put_flash(
  #           updated_socket,
  #           :info,
  #           "Syndicate #{syndicate.name} was only partially deactivated. Try again later!"
  #         )
  #       else
  #         :ok = SyndicateStore.deactivate_syndicate(syndicate)
  #         updated_socket
  #       end

  #     {:noreply, updated_socket}
  #   else
  #     error ->
  #       Logger.error("Unable complete syndicate deactivation: #{inspect(error)}")
  #       {:noreply, socket |> put_flash(:error, "Unable complete syndicate deactivation!")}
  #   end
  # end

  # def handle_info(message, socket) do
  #   Logger.error("Unknown message received: #{inspect(message)}")

  #   {:noreply, socket |> put_flash(:error, "Something unexpected happened, please report it!")}
  # end

  ####################
  # Helper Functions #
  ####################

  @spec disable_button?([Syndicate.t()], [Syndicate.t()]) :: boolean
  def disable_button?(selected_syndicates, inactive_syndicates),
    do:
      Enum.empty?(selected_syndicates) or
        Enum.sort(selected_syndicates) == Enum.sort(inactive_syndicates)
end
