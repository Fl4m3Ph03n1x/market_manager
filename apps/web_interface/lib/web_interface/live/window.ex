defmodule WebInterface.Live.Window do
  @moduledoc """
  Rrepresents the full interface. This module is responsible for receiving
  messages from its LiveView subcomponents and to give them the information
  they need to perform adequatly.

  It is the starting point for the user interface.
  """

  use WebInterface, :live_view

  require Logger

  alias Phoenix.LiveView
  alias Phoenix.LiveView.{Rendered, Socket}
  alias WebInterface.{Commands, Strategies, Syndicates}

  alias __MODULE__.{Main, Sidebar, OperationProgress}

  #############
  # Callbacks #
  #############

  @impl LiveView
  def mount(_params, _session, socket) do
    commands = Commands.list_commands()
    strategies = Strategies.list_strategies()
    syndicates = Syndicates.list_syndicates()

    socket =
      assign(socket,
        commands: commands,
        selected_command: hd(commands),
        strategies: strategies,
        selected_strategy: hd(strategies),
        syndicates: syndicates,
        syndicates_to_deactivate: [],
        syndicates_to_activate: [],
        active_syndicates: [],
        progress_bar_value: 0,
        operation_in_progress: false,
        current_syndicate: nil
      )

    {:ok, socket}
  end

  @impl LiveView
  @spec render(map) :: Rendered.t()
  def render(assigns) do
    ~H"""
    <div id="commands" class="container row">
      <%= live_component(Sidebar, [
        commands: @commands,
        selected_command: @selected_command,
        operation_in_progress: @operation_in_progress
      ], id: 7244) %>
      <%= live_component(Main, [
        selected_command: @selected_command,
        selected_strategy: @selected_strategy,
        syndicates_to_activate: @syndicates_to_activate,
        syndicates_to_deactivate: @syndicates_to_deactivate,
        active_syndicates: @active_syndicates,
        strategies: @strategies,
        syndicates: @syndicates,
        operation_in_progress: @operation_in_progress
      ], id: 4278) %>
      <%= live_component(OperationProgress, [
        progress_bar_value: @progress_bar_value,
        operation_in_progress: @operation_in_progress,
        current_syndicate: @current_syndicate
      ], id: 5919) %>
    </div>
    """
  end

  @impl LiveView
  @spec handle_event(String.t(), map, Socket.t()) :: {:noreply, Socket.t()}
  def handle_event("show", %{"id" => id}, socket) do
    command =
      id
      |> String.to_existing_atom()
      |> Commands.get_command()

    socket = assign(socket, selected_command: command)
    {:noreply, socket}
  end

  def handle_event(
        "execute_command",
        %{"command" => "activate", "strategy" => strategy, "syndicates" => syndicates},
        socket
      ) do
    Commands.execute(%{
      command: :activate,
      strategy: String.to_existing_atom(strategy),
      syndicates: string_to_selected_syndicates(syndicates)
    })

    {:noreply, socket}
  end

  def handle_event(
        "execute_command",
        %{"command" => "deactivate", "syndicates" => syndicates},
        socket
      ) do
    Commands.execute(%{
      command: :deactivate,
      syndicates: string_to_selected_syndicates(syndicates)
    })

    {:noreply, socket}
  end

  def handle_event("authenticate", %{"cookie" => cookie, "token" => token}, socket),
    do:
      %{
        command: :authenticate,
        cookie: cookie,
        token: token
      }
      |> Commands.execute()
      |> handle_authenticate_response(socket)

  def handle_event("activate-filters", %{"strategy" => strat, "syndicates" => synds}, socket) do
    new_strategy =
      strat
      |> String.to_existing_atom()
      |> Strategies.get_strategy()

    new_syndicates =
      synds
      |> Enum.filter(&by_not_empty_string/1)
      |> Enum.map(&Syndicates.get_syndicate/1)

    socket =
      assign(socket, selected_strategy: new_strategy, syndicates_to_activate: new_syndicates)

    {:noreply, socket}
  end

  def handle_event("deactivate-filters", %{"syndicates" => synds}, socket) do
    new_syndicates =
      synds
      |> Enum.filter(&by_not_empty_string/1)
      |> Enum.map(&Syndicates.get_syndicate/1)

    socket = assign(socket, syndicates_to_deactivate: new_syndicates)
    {:noreply, socket}
  end

  @impl LiveView
  def handle_info({:activate, syndicate, :done}, socket) do
    assigns = Map.get(socket, :assigns)

    syndicates_to_activate =
      Map.get(assigns, :syndicates_to_activate) -- [Syndicates.get_syndicate(syndicate)]

    operation_in_progress =
      if syndicates_to_activate |> Enum.empty?() do
        false
      else
        true
      end

    socket =
      assign(socket,
        operation_in_progress: operation_in_progress,
        syndicates_to_activate: syndicates_to_activate,
        progress_bar_value: 0,
        current_syndicate: nil,
        active_syndicates:
          Map.get(assigns, :active_syndicates) ++ [Syndicates.get_syndicate(syndicate)]
      )

    IO.inspect(self(), label: "PID")
    Logger.info("#{syndicate} activation completed")
    {:noreply, socket}
  end

  def handle_info(
        {:activate, syndicate, {current, total, {:error, _reason, _id} = result}},
        socket
      ) do
    socket =
      assign(
        socket,
        progress_bar_value: round(current / total * 100),
        operation_in_progress: true,
        current_syndicate: syndicate |> Syndicates.get_syndicate() |> Map.get(:name)
      )

    Logger.error("Ordered placement failed: #{inspect(result)}")
    {:noreply, socket}
  end

  def handle_info({:activate, syndicate, {current, total, {:ok, _order_id} = result}}, socket) do
    socket =
      assign(
        socket,
        progress_bar_value: round(current / total * 100),
        operation_in_progress: true,
        current_syndicate: syndicate |> Syndicates.get_syndicate() |> Map.get(:name)
      )

    Logger.info("Ordered placement succeeded: #{inspect(result)}")
    {:noreply, socket}
  end

  def handle_info({:activate, _syndicate, {:error, result}}, socket) do
    Logger.error("Operation failed: #{inspect(result)}")
    {:noreply, socket}
  end

  def handle_info({:activate, syndicate, data}, socket) do
    Logger.warning("Unknown event detected for #{syndicate}: #{inspect(data)}")
    {:noreply, socket}
  end

  def handle_info({:deactivate, syndicate, :done}, socket) do
    assigns = Map.get(socket, :assigns)

    syndicates_to_deactivate =
      Map.get(assigns, :syndicates_to_deactivate) -- [Syndicates.get_syndicate(syndicate)]

    operation_in_progress =
      if syndicates_to_deactivate |> Enum.empty?() do
        false
      else
        true
      end

    socket =
      assign(socket,
        operation_in_progress: operation_in_progress,
        syndicates_to_deactivate: syndicates_to_deactivate,
        progress_bar_value: 0,
        current_syndicate: nil,
        active_syndicates:
          Map.get(assigns, :active_syndicates) -- [Syndicates.get_syndicate(syndicate)]
      )

    Logger.info("#{syndicate} deactivation completed")
    {:noreply, socket}
  end

  def handle_info(
        {:deactivate, syndicate, {current, total, {:error, _reason, _id} = result}},
        socket
      ) do
    socket =
      assign(
        socket,
        progress_bar_value: round(current / total * 100),
        operation_in_progress: true,
        current_syndicate: syndicate |> Syndicates.get_syndicate() |> Map.get(:name)
      )

    Logger.error("Ordered deletion failed: #{inspect(result)}")
    {:noreply, socket}
  end

  def handle_info({:deactivate, syndicate, {current, total, {:ok, _order_id} = result}}, socket) do
    socket =
      assign(
        socket,
        progress_bar_value: round(current / total * 100),
        operation_in_progress: true,
        current_syndicate: syndicate |> Syndicates.get_syndicate() |> Map.get(:name)
      )

    Logger.info("Ordered deletion succeeded: #{inspect(result)}")
    {:noreply, socket}
  end

  def handle_info({:deactivate, _syndicate, {:error, result}}, socket) do
    Logger.error("Operation failed: #{inspect(result)}")
    {:noreply, socket}
  end

  def handle_info({:deactivate, syndicate, data}, socket) do
    Logger.warning("Unknown event detected for #{syndicate}: #{inspect(data)}")
    {:noreply, socket}
  end

  #####################
  # Private Functions #
  #####################

  @spec string_to_selected_syndicates(String.t()) :: [Syndicates.syndicate_info()]
  defp string_to_selected_syndicates(syndicates_string),
    do:
      syndicates_string
      |> String.split(";")
      |> Enum.filter(&by_not_empty_string/1)
      |> Enum.map(&Syndicates.get_syndicate/1)

  @spec by_not_empty_string(String.t()) :: boolean
  defp by_not_empty_string(string), do: string !== ""

  @spec handle_authenticate_response(any, Socket.t()) :: {:noreply, Socket.t()}
  defp handle_authenticate_response({:ok, :success}, socket),
    do: {:noreply, put_flash(socket, :info, "Authentication saved successfully!}")}

  defp handle_authenticate_response(results, socket) do
    Logger.error("#{inspect(results)}")
    {:noreply, put_flash(socket, :error, "Unable to persist authentication information.")}
  end
end
