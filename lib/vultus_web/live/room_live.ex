defmodule VultusWeb.RoomLive do
  @moduledoc """
    This module is responsible for handiling messages and message events.
  """

  use VultusWeb, :live_view
  require Logger

  @impl true
  def mount(%{"room_id" => room_id}, _session, socket) do
    #todo Mount is called twice so you see a username change when loading
    topic = "room:" <> room_id
    username = MnemonicSlugs.generate_slug(2)
    chat_color = RandomColor.hex(luminosity: :light)
    uuid = UUID.uuid4()
    private = topic <> ":" <> uuid

    if connected?(socket) do
      VultusWeb.Endpoint.subscribe(topic)
      VultusWeb.Endpoint.subscribe(private)
      VultusWeb.Presence.track(self(), topic, username, %{chat_color: chat_color, uuid: uuid})
    end

    socket = assign(
      socket,
      room_id: room_id,
      message: "", #for clearing text input
      topic: topic,
      username: username,
      private: [],
      offer_requests: [],
      uuid: uuid,
      chat_color: chat_color,
      user_list: [],
      messages: [],
      ice_candidate_offers: [],
      sdp_offers: [],
      answers: [],
      temporary_assigns: [messages: []] #default state for messages
    )
    {:ok, socket}
  end

######################## Handle Events ########################

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    message = %{uuid: UUID.uuid4(), content: message, username: socket.assigns.username, chat_color: socket.assigns.chat_color}
    VultusWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("form_update", %{"chat" => %{"message" => message}}, socket) do
    {:noreply, assign(socket, message: message)}
  end

  @impl true
  def handle_event("join_call",_params, socket) do
    for user <- socket.assigns.user_list do
      send_direct_message(socket.assigns.room_id, get_user_meta(user, :uuid), "request_offers", %{from_user: socket.assigns.uuid})
    end
    {:noreply, socket}
  end

######################## Web RTC ########################

  @impl true
  def handle_event("new_ice_canidate", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.uuid})
    send_direct_message(socket.assigns.room_id, payload["toUser"], "new_ice_candidate", payload)
  end

  @impl true
  def handle_event("new_sdp_offer", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.uuid})

    send_direct_message(socket.assigns.room_id, payload["toUser"], "new_sdp_offer", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_event("new_answer", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.uuid})

    send_direct_message(socket.assigns.room_id, payload["toUser"], "new_answer", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "new_ice_candidate", payload: payload}, socket) do
    socket = assign(socket, :ice_candidate_offers, socket.assigns.ice_candidate_offers ++ [payload])
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "new_sdp_offer", payload: payload}, socket) do
    socket = assign(socket, :sdp_offers, socket.assigns.ice_candidate_offers ++ [payload])
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "new_answer", payload: payload},  socket) do
    socket = assign(socket, :answers, socket.assigns.answers ++ [payload])
    {:noreply, socket}
  end
######################## Handle Info ########################

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
      |> Enum.map(fn username -> %{type: :system, uuid: UUID.uuid4(), content: "#{username} left", username: "", chat_color: "#828282"}
    end)

    user_list = VultusWeb.Presence.list(socket.assigns.topic)
    socket = assign(socket, messages: join_messages ++ leave_messages, user_list: user_list)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "request_offers", payload: request}, socket) do
    socket = assign(socket, :offer_requests, socket.assigns.offer_requests ++ [request])
    IO.puts("\n\n\n\n\n")
    IO.inspect(socket.assigns.offer_requests)
    IO.puts("\n\n\n\n\n")
    {:noreply, socket}
  end

######################## Private Messaging ########################

defp send_direct_message(room_id, to_user, event, payload) do
  VultusWeb.Endpoint.broadcast_from(
    self(),
    "room:" <> room_id <> ":" <> to_user,
    event,
    payload
  )
end









######################## Helper Methods ########################

  def get_user_meta(user, meta_key) do
    #todo there has got to be a better way of doing this shit.
    user
    |> elem(1)
    |> Map.fetch(:metas)
    |> elem(1)
    |> List.first()
    |> Map.fetch(meta_key)
    |> elem(1)
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

end
