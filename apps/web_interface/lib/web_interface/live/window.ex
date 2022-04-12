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
  alias WebInterface.{Commands, Strategies, Syndicates}

  alias __MODULE__.{Main, Sidebar}

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
        active_syndicates: []
      )

    {:ok, socket}
  end

  @impl LiveView
  def render(assigns) do
    ~H"""
    <div id="commands" class="container row">
      <%= live_component(Sidebar, [commands: @commands, selected_command: @selected_command], id: 1) %>
      <%= live_component(Main, [
        selected_command: @selected_command,
        selected_strategy: @selected_strategy,
        syndicates_to_activate: @syndicates_to_activate,
        syndicates_to_deactivate: @syndicates_to_deactivate,
        active_syndicates: @active_syndicates,
        strategies: @strategies,
        syndicates: @syndicates
      ], id: 2) %>
    </div>
    """
  end

  @impl LiveView
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
        %{"command" => "activate", "strategy" => strategy, "syndicates" => syndicates} = data,
        socket
      ), do:
        %{
          command: String.to_existing_atom("activate"),
          strategy: String.to_existing_atom(strategy),
          syndicates: string_to_selected_syndicates(syndicates)
        }
        |> Commands.execute()
        |> handle_activate_response(socket, string_to_selected_syndicates(syndicates))

  def handle_event(
        "execute_command",
        %{"command" => command, "strategy" => strategy, "syndicates" => syndicates} = data,
        socket
      ), do:
        %{
          command: String.to_existing_atom(command),
          strategy: String.to_existing_atom(strategy),
          syndicates: string_to_selected_syndicates(syndicates)
        }
        |> Commands.execute()
        |> handle_commands_response(socket)

  def handle_event("authenticate", %{"cookie" => cookie, "token" => token}, socket), do:
    %{
      command: :authenticate,
      cookie: cookie,
      token: token
    }
    |> Commands.execute()
    |> handle_commands_response(socket)

  def handle_event("activate-filters", %{"strategy" => strat, "syndicates" => synds} = data, socket) do
    new_strategy =
      strat
      |> String.to_existing_atom()
      |> Strategies.get_strategy()

    new_syndicates =
      synds
      |> Enum.filter(&by_not_empty_string/1)
      |> Enum.map(&Syndicates.get_syndicate/1)

    socket = assign(socket, selected_strategy: new_strategy, syndicates_to_activate: new_syndicates)
    {:noreply, socket}
  end

  def handle_event("deactivate-filters", %{"syndicates" => synds} = data, socket) do
    new_syndicates =
      synds
      |> Enum.filter(&by_not_empty_string/1)
      |> Enum.map(&Syndicates.get_syndicate/1)

    socket = assign(socket, syndicates_to_deactivate: new_syndicates)
    {:noreply, socket}
  end

  defp string_to_selected_syndicates(syndicates_string),
    do:
      syndicates_string
      |> String.split(";")
      |> Enum.filter(&by_not_empty_string/1)
      |> Enum.map(&Syndicates.get_syndicate/1)

  defp by_not_empty_string(string), do: string !== ""

  defp handle_commands_response({:ok, :success}, socket),
    do: {:noreply, put_flash(socket, :info, "All orders placed successfully !}")}

  defp handle_commands_response(results, socket),
    do: {:noreply, put_flash(socket, :info, "Request completed: #{inspect(results)}")}

  defp handle_activate_response({:ok, :success}, socket, syndicates) do
    socket = assign(socket, active_syndicates: syndicates)
    {:noreply, put_flash(socket, :info, "All orders placed successfully!}")}
  end

  defp handle_activate_response(results, socket, syndicates) do
    result_per_syndicate = Enum.zip(syndicates, results)

    successful_synds = Enum.filter(
      result_per_syndicate,
      fn  {_syn, {:ok, :success}} -> true
          {_syn, _result} -> false
      end
    )
    |> Enum.map(fn {syn, _result} -> syn end)

    socket = assign(socket, active_syndicates: successful_synds)

    failed_synds = Enum.filter(
      result_per_syndicate,
      fn  {_syn, {:ok, :success}} -> false
          {_syn, _result} -> true
      end
    )
    |> log_error("Failed syndicate requests")
    |> Enum.map(fn {syn, _result} -> syn end)

    message = "The following syndicate requests failed due errors: #{Enum.map(failed_synds, fn synd -> synd.name end) |> Enum.join(", ")}"

    {:noreply, put_flash(socket, :error, message)}
  end

  defp handle_activate_response(results, socket, _syndicates) do
    Logger.warning("Unknown resutl from command 'Activate': #{inspect(results)}")
    {:noreply, socket}
  end

  defp log_error(data, message) do
    Logger.error(message <> ": #{inspect(data)}")
    data
  end
end
