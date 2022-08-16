defmodule VultuschatWeb.RoomLive do
  @moduledoc """
    This module is responsible for handiling messages and message events.
  """

  use VultuschatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"room_id" => room_id}, _session, socket) do
    topic = "room:" <> room_id
    if connected?(socket), do: VultuschatWeb.Endpoint.subscribe(topic)

    socket = assign(
      socket,
      room_id: room_id,
      topic: topic,
      messages: [%{uuid: UUID.uuid4(), content: "What's up loser?"}],
      temporary_assigns: [messages: []] #default state for messages
    )
    {:ok, socket}
  end

######################## Event Handling ########################

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    message = %{uuid: UUID.uuid4(), content: message}
    VultuschatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    socket = assign(socket, messages: [message])
    {:noreply, socket}
  end
end
