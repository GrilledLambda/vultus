defmodule VultuschatWeb.RoomLive do
  @moduledoc """
    This module is responsible for handiling messages and message events.
  """

  use VultuschatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"room_id" => room_id}, _session, socket) do
    topic = "room:" <> room_id
    username = MnemonicSlugs.generate_slug(2)
    chat_color = RandomColor.hex(luminosity: :light)

    if connected?(socket) do
      VultuschatWeb.Endpoint.subscribe(topic)
      VultuschatWeb.Presence.track(self(), topic, username, %{chat_color: chat_color})
    end

    socket = assign(
      socket,
      room_id: room_id,
      topic: topic,
      username: username,
      chat_color: chat_color,
      messages: [%{uuid: UUID.uuid4(), content: "#{username} joined.", username: username, chat_color: chat_color}],
      temporary_assigns: [messages: []] #default state for messages
    )
    {:ok, socket}
  end

######################## Event Handling ########################

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    message = %{uuid: UUID.uuid4(), content: message, username: socket.assigns.username, chat_color: socket.assigns.chat_color}
    VultuschatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    socket = assign(socket, messages: [message])
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    {:noreply, socket}
  end
end
