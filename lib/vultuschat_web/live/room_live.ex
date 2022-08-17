defmodule VultuschatWeb.RoomLive do
  @moduledoc """
    This module is responsible for handiling messages and message events.
  """

  use VultuschatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"room_id" => room_id}, _session, socket) do
    #todo Mount is called twice so you see a username change when loading
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
      message: "", #for clearing text input
      topic: topic,
      username: username,
      chat_color: chat_color,
      user_list: [],
      messages: [],
      temporary_assigns: [messages: []] #default state for messages
    )
    {:ok, socket}
  end

######################## Event Handling ########################

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    message = %{uuid: UUID.uuid4(), content: message, username: socket.assigns.username, chat_color: socket.assigns.chat_color}
    VultuschatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("form_update", %{"chat" => %{"message" => message}}, socket) do
    {:noreply, assign(socket, message: message)}
  end


  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    socket = assign(socket, messages: [message])
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    join_messages =
      joins
      |> Map.keys()
      |> Enum.map(fn username -> %{type: :system, uuid: UUID.uuid4(), content: "#{username} joined", username: "", chat_color: "#fff"}
    end)

    leave_messages =
      leaves
      |> Map.keys()
      |> Enum.map(fn username -> %{type: :system, uuid: UUID.uuid4(), content: "#{username} left", username: "", chat_color: "#DFDFDF"}
    end)

    user_list = VultuschatWeb.Presence.list(socket.assigns.topic)
    socket = assign(socket, messages: join_messages ++ leave_messages, user_list: user_list)

    {:noreply, socket}
  end

  def display_message(%{type: :system, uuid: uuid, content: content, chat_color: chat_color}) do
    ~E"""
    <div class="message" id=<%= uuid %> style="background: <%= chat_color %>">
    <em><%= content %></em>
    </div>
    """
  end

  def display_message(%{uuid: uuid, content: content, username: username, chat_color: chat_color}) do
    ~E"""
    <div class="message" id=<%= uuid %> style="background: <%= chat_color %>">
    <%= content %>
    <div class="author" > <%= username %> </div>
    </div>
    """
  end

  def get_chat_color(user) do
    #todo there has got to be a better way of doing this shit.
    user
    |> elem(1)
    |> Map.fetch(:metas)
    |> elem(1)
    |> List.first()
    |> Map.fetch(:chat_color)
    |> elem(1)
  end

end
