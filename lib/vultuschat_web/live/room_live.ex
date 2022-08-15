defmodule VultuschatWeb.RoomLive do
  use VultuschatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"room_id" => room_id}, _session, socket) do
    socket = assign(socket, room_id: room_id)
    {:ok, socket}
  end

end
