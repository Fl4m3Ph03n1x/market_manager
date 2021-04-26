defmodule WebInterfaceWeb.CommandsLive do
  use WebInterfaceWeb, :live_view

  alias Phoenix.LiveView
  alias WebInterface.{Commands, Strategies, Syndicates}

  @impl true
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
    ~L"""
    <div id="commands" class="grid grid-cols-12 gap-2 justify-evenly">
      <div class="sidebar col-span-2">
        <nav>
          <%= for command <- @commands do %>
            <a href="#"
              phx-click="show"
              phx-value-id="<%= command.id %>"
              class="<%= if command == @selected_command, do: 'active' %>">
              <%= command.name %>
            </a>
          <% end %>
        </nav>
      </div>
      <div class="main col-span-10">

        <div class="header">
          <h2>Description</h2>
          <span><%= @selected_command.description %></span>
        </div>

        <div class="body">
          <form phx-change=filters>

            <div class="<%= if @selected_command.id == :deactivate, do: 'hide_strategies' %> strategies">
              <%= for strat <- @strategies  do %>
                <%= strategy_radio_button(strat: strat, checked: strat == @selected_strategy) %>
              <% end %>
            </div>

            <div class="syndicates">
              <input type="hidden" name="syndicates[]" value="">
              <%= for synd <- @syndicates  do %>
                <%= syndicate_checkbox(synd: synd, checked: synd in @selected_syndicates) %>
              <% end %>
            </div>
          </form>

          <div class="button">
            <button
              phx-click="execute_command"
              phx-value-command="<%= @selected_command.id %>"
              phx-value-strategy="<%= @selected_strategy.id %>"
              phx-value-syndicates="<%= selected_syndicates_to_string(@selected_syndicates) %>"
              type="button">
                Execute Command
            </button>
          </div>
        </div>

      </div>
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
      |> Enum.map(&String.to_existing_atom/1)
      |> Enum.map(&Syndicates.get_syndicate/1)

    socket = assign(socket, selected_strategy: new_strategy, selected_syndicates: new_syndicates)
    {:noreply, socket}
  end

  defp strategy_radio_button(assigns) do
    assigns = Enum.into(assigns, %{})

    ~L"""
    <input type="radio" id="<%= @strat.id %>"
            name="strategy" value="<%= @strat.id %>"
            <%= if @checked, do: "checked" %> />
    <label for="<%= @strat.id %>"><%= @strat.name %></label>
    <span class="description"><%= @strat.description %></span>
    </br>
    """
  end

  defp syndicate_checkbox(assigns) do
    assigns = Enum.into(assigns, %{})

    ~L"""
    <input type="checkbox" id="<%= @synd.id %>"
            name="syndicates[]" value="<%= @synd.id %>"
            <%= if @checked, do: "checked" %>>

    <label for="<%= @synd.id %>"><%= @synd.name %></label>
    </br>
    """
  end

  defp selected_syndicates_to_string(syndicates),
    do:
      syndicates
      |> Enum.map(&Syndicates.get_id/1)
      |> Enum.map(&Atom.to_string/1)
      |> Enum.join(";")

  defp string_to_selected_syndicates(syndicates_string),
    do:
      syndicates_string
      |> String.split(";")
      |> Enum.filter(&by_not_empty_string/1)
      |> Enum.map(&String.to_existing_atom/1)
      |> Enum.map(&Syndicates.get_syndicate/1)

  defp by_not_empty_string(string), do: string !== ""

  defp handle_commands_response({:ok, _result}, socket), do: {:noreply, socket}

  defp handle_commands_response({:error, reason}, socket),
    do: {:noreply, put_flash(socket, :error, "Request failed: #{inspect(reason)}")}
end
