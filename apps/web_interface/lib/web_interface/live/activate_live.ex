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

    updated_socket =
      assign(
        socket,
        user: user,
        all_syndicates_active?: all_active,
        syndicates: syndicates,
        strategies: strategies,
        inactive_syndicates: syndicates -- active_syndicates,
        selected_strategy: nil
      )

    {:ok, updated_socket}
  end

  @spec strategy_radio_button(keyword(any)) :: Rendered.t()
  defp strategy_radio_button(assigns) do
    assigns = Enum.into(assigns, %{})

    ~H"""
    <div class="radio-button row">
      <div class="choice column column-25">
        <input type="radio" id={@strategy.id} name="strategy" value={@strategy.id} checked={@checked}/>
        <label for={@strategy.id}><%= @strategy.name %></label>
      </div>
      <div class="description column">
        <p><%= @strategy.description %></p>
      </div>
    </div>
    """
  end

  @spec syndicate_checkbox(keyword(any)) :: Rendered.t()
  defp syndicate_checkbox(assigns) do
    assigns = Enum.into(assigns, %{})

    ~H"""
      <div class="row single-syndicate">
        <input class="column single-checkbox" type="checkbox" id={checkbox_id(@syndicate)} name="syndicates[]" value={@syndicate.id} checked={false}>
        <label for={checkbox_id(@syndicate)} class="column"><%= @syndicate.name %></label>
      </div>
    """
  end

  @spec checkbox_id(Syndicate.t()) :: String.t()
  defp checkbox_id(syndicate), do: "activate:#{syndicate.id}"

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(message, socket) do
    Logger.error("Unknown message received: #{inspect(message)}")
    {:noreply, socket |> put_flash(:error, "Something unexpected happened, please report it!")}
  end
end
