defmodule WebInterface.DeactivateLive do
  use WebInterface, :live_view

  require Logger

  alias Manager
  alias WebInterface.Persistence.{Syndicate, User}

  @impl true
  def mount(_params, _session, socket) do
    with  {:ok, user} <- User.get_user(),
          {:ok, syndicates} <- Syndicate.get_syndicates(),
          {:ok, inactive_syndicates} <- Syndicate.get_inactive_syndicates(),
          {:ok, selected_inactive_syndicates} <- Syndicate.get_selected_inactive_syndicates() do
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
                deactivation_current_syndicate: nil
              )

            {:ok, updated_socket}
            else
              error ->
                Logger.error("Unable to show deactivation page: #{inspect(error)}")
                {:error, socket |> put_flash(:error, "Unable to show deactivation page!")}
          end
  end

  @impl true
  def handle_event("execute", %{"syndicates" => syndicate_ids}, socket) do

    with {:ok, [syndicate | _rest] = syndicates} <- Syndicate.get_all_syndicates_by_id(syndicate_ids),
      :ok <- Manager.deactivate(Atom.to_string(syndicate.id)) do

      updated_socket =
        socket
        |> assign(selected_inactive_syndicates: syndicates)
        |> assign(deactivation_in_progress: true)
        |> assign(deactivation_current_syndicate: syndicate)
        |> assign(deactivation_progress: 0)

      {:noreply, updated_socket}
    else
      err ->
        Logger.error("Unable to retrieve data: #{inspect(err)}")
        {:noreply, socket |> put_flash(:error, "Unable to retrieve data!")}
    end
  end

  def handle_event("change", %{"syndicates" => syndicate_ids} = e, socket) do
    with {:ok, syndicates} <- Syndicate.get_all_syndicates_by_id(syndicate_ids),
         {:ok, inactive_syndicates} <- Syndicate.get_inactive_syndicates(),
         new_selected_syndicates =
           Enum.uniq(syndicates ++ inactive_syndicates),
         :ok <- Syndicate.set_selected_inactive_syndicates(new_selected_syndicates) do
      {:noreply,
       assign(socket, selected_inactive_syndicates: new_selected_syndicates)}
    else
      err ->
        Logger.error("Unable to retrieve change data: #{inspect(err)}")
        {:noreply, socket |> put_flash(:error, "Unable to retrieve data!")}
    end
  end

  def handle_event("change", no_syndicates_selected, socket) do
    with {:ok, inactive_syndicates} <- Syndicate.get_inactive_syndicates(),
         :ok <- Syndicate.set_selected_inactive_syndicates(inactive_syndicates) do
      {:noreply,
       assign(socket, selected_inactive_syndicates: inactive_syndicates)}
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
  def handle_info({:deactivate, syndicate_name, {:error, reason} = error}, socket) do
    Logger.error("Unable to deactivate syndicate #{syndicate_name}: #{inspect(error)}")

    {:noreply,
     put_flash(
       socket,
       :error,
       "Unable to deactivate syndicate #{syndicate_name} due to '#{reason}'."
     )}
  end

  def handle_info(
        {:deactivate, syndicate, {current_item, total_items, {:error, reason, _item} = error}},
        socket
      ) do
    Logger.error("Order deletion for item of #{syndicate} failed: #{inspect(error)}")

    updated_socket =
      socket
      |> assign(deactivation_progress: round(current_item / total_items * 100))
      |> put_flash(:error, "Unable to delete an order for #{syndicate} due to '#{reason}'.")

    {:noreply, updated_socket}
  end

  def handle_info(
        {:deactivate, syndicate,
         {current_item, total_items, {:ok, %Shared.Data.PlacedOrder{item_id: item_id}}}},
        socket
      ) do
    Logger.info("Order deleted for #{syndicate}: #{item_id}")

    {:noreply, assign(socket, deactivation_progress: round(current_item / total_items * 100))}
  end

  def handle_info({:deactivate, syndicate_id_str, :done}, socket) do
    Logger.info("Deactivation of #{syndicate_id_str} complete.")

    with {:ok, syndicate} <- Syndicate.get_syndicate_by_id(syndicate_id_str),
         :ok <- Syndicate.deactivate_syndicate(syndicate),
         {:ok, selected_syndicates} <- Syndicate.get_selected_inactive_syndicates(),
         {:ok, inactive_syndicates} <- Syndicate.get_inactive_syndicates(),
         new_selected_syndicates =
           Enum.uniq(selected_syndicates ++ inactive_syndicates),
         :ok <- Syndicate.set_selected_inactive_syndicates(new_selected_syndicates) do
      missing_syndicates =
        selected_syndicates
        |> MapSet.new()
        |> MapSet.difference(MapSet.new(inactive_syndicates))
        |> MapSet.to_list()
        |> List.flatten()

      to_assign =
        if Enum.empty?(missing_syndicates) do
          [deactivation_current_syndicate: nil, deactivation_in_progress: false]
        else
          [next_syndicate | _rest] = missing_syndicates
          :ok = Manager.deactivate(Atom.to_string(next_syndicate.id))
          [deactivation_current_syndicate: next_syndicate, deactivation_progress: 0]
        end

      updated_socket =
        socket
        |> assign(inactive_syndicates: inactive_syndicates)
        |> assign(selected_inactive_syndicates: new_selected_syndicates)
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

  @spec disable_button?([Syndicates.t()], [Syndicates.t()]) :: boolean
  def disable_button?(selected_syndicates, inactive_syndicates),
    do: Enum.empty?(selected_syndicates) or Enum.sort(selected_syndicates) == Enum.sort(inactive_syndicates)

  @spec progress_bar_message(Syndicates.t() | nil) :: String.t()
  def progress_bar_message(nil), do: "Operation in progress ..."

  def progress_bar_message(deactivation_current_syndicate),
    do: "Deactivation for #{deactivation_current_syndicate.name} in progress ..."
end
