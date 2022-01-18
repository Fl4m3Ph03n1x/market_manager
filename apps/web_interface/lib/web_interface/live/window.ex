defmodule WebInterface.Live.Window do
  @moduledoc """
  Rrepresents the full interface. This module is responsible for receiving
  messages from its LiveView subcomponents and to give them the information
  they need to perform adequatly.

  It is the starting point for the user interface.
  """

  use WebInterface, :live_view

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
        selected_syndicates: []
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
        selected_syndicates: @selected_syndicates,
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
        %{"command" => command, "strategy" => strategy, "syndicates" => syndicates},
        socket
      ),
      do:
        %{
          command: String.to_existing_atom(command),
          strategy: String.to_existing_atom(strategy),
          syndicates: string_to_selected_syndicates(syndicates)
        }
        |> Commands.execute()
        |> handle_commands_response(socket)

  def handle_event("filters", %{"strategy" => strat, "syndicates" => synds}, socket) do
    new_strategy =
      strat
      |> String.to_existing_atom()
      |> Strategies.get_strategy()

    new_syndicates =
      synds
      |> Enum.filter(&by_not_empty_string/1)
      |> Enum.map(&Syndicates.get_syndicate/1)

    socket = assign(socket, selected_strategy: new_strategy, selected_syndicates: new_syndicates)
    {:noreply, socket}
  end

  defp string_to_selected_syndicates(syndicates_string),
    do:
      syndicates_string
      |> String.split(";")
      |> Enum.filter(&by_not_empty_string/1)
      |> Enum.map(&Syndicates.get_syndicate/1)

  defp by_not_empty_string(string), do: string !== ""

  defp handle_commands_response(results, socket),
    do: {:noreply, put_flash(socket, :info, "Request completed: #{inspect(results)}")}
end
