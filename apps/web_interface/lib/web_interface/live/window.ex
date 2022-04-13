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
        %{"command" => "activate", "strategy" => strategy, "syndicates" => syndicates},
        socket
      ), do:
        %{
          command: :activate,
          strategy: String.to_existing_atom(strategy),
          syndicates: string_to_selected_syndicates(syndicates)
        }
        |> Commands.execute()
        |> handle_activate_response(socket, string_to_selected_syndicates(syndicates))

  def handle_event(
        "execute_command",
        %{"command" => "deactivate", "syndicates" => syndicates},
        socket
      ), do:
        %{
          command: :deactivate,
          syndicates: string_to_selected_syndicates(syndicates)
        }
        |> Commands.execute()
        |> handle_deactivate_response(socket, string_to_selected_syndicates(syndicates))

  def handle_event("authenticate", %{"cookie" => cookie, "token" => token}, socket), do:
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

    socket = assign(socket, selected_strategy: new_strategy, syndicates_to_activate: new_syndicates)
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

  defp string_to_selected_syndicates(syndicates_string),
    do:
      syndicates_string
      |> String.split(";")
      |> Enum.filter(&by_not_empty_string/1)
      |> Enum.map(&Syndicates.get_syndicate/1)

  defp by_not_empty_string(string), do: string !== ""


  defp handle_authenticate_response({:ok, :success}, socket),
    do: {:noreply, put_flash(socket, :info, "Authentication saved successfully!}")}

  defp handle_authenticate_response(results, socket) do
    Logger.error("#{inspect(results)}")
    {:noreply, put_flash(socket, :error, "Unable to persist authentication information.")}
  end

  defp handle_activate_response(results, socket, syndicates) do
    assigns = Map.get(socket, :assigns)
    result_per_syndicate = Enum.zip(syndicates, results)

    successful_synds =
      result_per_syndicate
      |> Enum.filter(&success_result?/1)
      |> Enum.map(&syndicate_from_result_tuple/1)

    socket =
      socket
      |> assign(active_syndicates: Map.get(assigns, :active_syndicates) -- successful_synds)
      |> assign(syndicates_to_activate: Map.get(assigns, :syndicates_to_activate) -- successful_synds)

    # we consider partial success a failure
    failures = Enum.filter(result_per_syndicate, &failure_result?/1)

    if Enum.empty?(failures) do
      {:noreply, put_flash(socket, :info, "All syndicate requests were placed successfully!")}
    else
      Logger.error("#{inspect(failures)}")
      syndicate_names = Enum.map_join(failures, ", ", &syndicate_name/1)

      {:noreply, put_flash(socket, :error, "The following syndicate requests failed due to errors: #{syndicate_names}")}
    end
  end


  defp handle_deactivate_response(results, socket, syndicates) do
    assigns = Map.get(socket, :assigns)
    result_per_syndicate = Enum.zip(syndicates, results)

    successful_synds =
      result_per_syndicate
      |> Enum.filter(&success_result?/1)
      |> Enum.map(&syndicate_from_result_tuple/1)

    socket =
      socket
      |> assign(active_syndicates: Map.get(assigns, :active_syndicates) -- successful_synds)
      |> assign(syndicates_to_deactivate: Map.get(assigns, :syndicates_to_deactivate) -- successful_synds)

    # we consider partial success a failure
    failures = Enum.filter(result_per_syndicate, &failure_result?/1)

    if Enum.empty?(failures) do
      {:noreply, put_flash(socket, :info, "All syndicate orders were removed successfully!")}
    else
      Logger.error("#{inspect(failures)}")
      syndicate_names = Enum.map_join(failures, ", ", &syndicate_name/1)

      {:noreply, put_flash(socket, :error, "The following syndicate requests failed due to errors: #{syndicate_names}")}
    end
  end

  @spec syndicate_from_result_tuple({map, any}) :: map
  defp syndicate_from_result_tuple({syn, _result}), do: syn

  @spec syndicate_name({map, any}) :: String.t()
  defp syndicate_name({syn, _result}), do: syn.name

  @spec success_result?({map, any}) :: boolean
  defp success_result?({_syn, {:ok, :success}}), do: true
  defp success_result?({_syn, _result}), do: false

  @spec failure_result?({map, any}) :: boolean
  defp failure_result?(tuple), do: not success_result?(tuple)
end
