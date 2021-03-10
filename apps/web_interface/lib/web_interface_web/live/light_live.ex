defmodule WebInterfaceWeb.LightLive do
  use WebInterfaceWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :brightness, 10)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <main role="main" class="container">
      <p class="alert alert-info" role="alert" phx-click="lv:clear-flash" phx-value-key="info"></p>
      <p class="alert alert-danger" role="alert" phx-click="lv:clear-flash" phx-value-key="error"></p>
      <div id="servers">
        <div class="sidebar">
          <nav>
            <a class="active" data-phx-link="patch" data-phx-link-state="push" href="/servers?id=4"><img src="/images/server.svg">
              Activate
            </a>
            <a data-phx-link="patch" data-phx-link-state="push" href="/servers?id=3"><img src="/images/server.svg">
              Deactivate
            </a>
          </nav>
        </div>

        <div id="selected-server" class="main">
          <div class="wrapper">
            <div class="card">
              <div class="header">
                <h2>cryptic-owl</h2>
                <span class="down">down</span>
              </div>
              <div class="body">
                <div class="row">
                  <div class="deploys">
                    <img src="/images/deploy.svg">
                    <span>2 deploys</span>
                  </div>
                  <span>5.0 MB</span>
                  <span>Elixir/Phoenix</span>
                </div>
                <h3>Git Repo</h3>
                <div class="repo">https://git.example.com/cryptic-owl.git</div>
                <h3>Last Commit</h3>
                <div class="commit">c497e91</div>
                <blockquote>First big launch! 🤞</blockquote>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
    """
  end

  @impl true
  def handle_event("on", _metadata, socket) do
    socket = assign(socket, :brightness, 100)
    {:noreply, socket}
  end

  def handle_event("up", _metadata, socket) do
    socket = update(socket, :brightness, &min(&1 + 10, 100))
    {:noreply, socket}
  end

  def handle_event("down", _metadata, socket) do
    socket = update(socket, :brightness, &max(&1 - 10, 0))
    {:noreply, socket}
  end

  def handle_event("off", _metadata, socket) do
    socket = assign(socket, :brightness, 0)
    {:noreply, socket}
  end


end
