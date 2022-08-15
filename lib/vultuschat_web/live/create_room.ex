defmodule VultuschatWeb.CreateRoom do
  use VultuschatWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :room_name, nil)
    {:ok, socket}
  end

######################## Event Handling ########################

  @impl true
  def handle_event("random-room", _params, socket) do
    #todo eventually make these user "hosted" rooms instead of random rooms

    random_url = "/" <> MnemonicSlugs.generate_slug(2)
    Logger.info(random_url)
    {:noreply, push_redirect(socket, to: random_url ) }
  end
end
