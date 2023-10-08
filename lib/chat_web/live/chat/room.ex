defmodule ChatWeb.ChatLive.Room do
  use ChatWeb, :live_view
  alias Chat.Rooms
  
  @impl true
  def mount(%{"id" => id}, _session, socket) do
    socket = Rooms.get(id) |> prepare_state(socket)
    {:ok, socket, layout: false}
  end

  @impl true
  def handle_event("send", %{"content" => content}, socket) do
    user_id = socket.assigns.current_user.id
    room_id = socket.assigns.room_id
    message = Rooms.Message.create(%{content: content, user_id: user_id})
    Rooms.add_message(room_id, message)
    
    
    {:noreply, socket}
  end

  @impl true
  def handle_info({:user_connected, user}, socket) do
    socket =
      socket
      |> put_flash(:info, "#{user.name} just joined to chat")
      |> stream_insert(:users, user)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:user_disconnect, user}, socket) do
    socket =
      socket
      |> put_flash(:info, "#{user.name} just leave the room")
      |> stream_delete(:users, user)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_sended, message}, socket) do
    socket =
      socket
      |> stream_insert(:messages, message)

    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    user = socket.assigns.current_user
    id = socket.assigns.room_id
    Rooms.remove_user(id, user)
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex gap-2 h-screen">
      <div id="users" class="bg-gray-200/20 hidden md:block w-52 flex flex-col gap-2 text-center pt-4 text-gray-700 text-md font-bold shadow border-l" phx-update="stream">
        <span :for={{id, user} <- @streams.users} id={id} :if={user.id != @current_user.id}> <%= user.name %></span>
      </div>
      <div class="justify-between flex flex-col max-h-screen h-full w-full">
        <div class="flex flex-col space-y-4 p-3 overflow-y-auto" id="messages" phx-update="stream">
          <.bubble
            :for={{id, message} <- @streams.messages}
            message={message}
            direction={if message.user_id == @current_user.id, do: :sender, else: :receiver}
            id={id}
          />
        </div>
        <.form
          for={@form}
          class="border-t-2 border-gray-200 px-4 pt-4 mx-0 justify-self-end"
          phx-submit="send"
          id="messanger"
        >
          <div class="relative flex">
            <input
              name={@form[:content].name}
              value={@form[:content].value}
              class="w-full focus:outline-none focus:placeholder-gray-400 text-gray-600 placeholder-gray-600 pl-12 bg-gray-200 rounded-md py-3"
            />
            <div class="absolute right-0 items-center inset-y-0 hidden sm:flex">
              <button class="hidden sm:inline-flex items-center justify-center rounded-lg px-4 py-3 transition duration-500 ease-in-out text-white bg-blue-500 hover:bg-blue-400 focus:outline-none">
                <span class="font-bold">Send</span>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  class="h-6 w-6 ml-2 transform rotate-90"
                >
                  <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z">
                  </path>
                </svg>
              </button>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  attr :direction, :atom,
    values: [:sender, :receiver],
    doc: "Define if bubble for sender or receiver"

  attr :message, :string, required: true
  attr :rest, :global
  

  defp bubble(%{direction: :receiver} = assigns) do
    ~H"""
    <div {@rest}>
      <div class="flex items-end">
        <div class="flex flex-col space-y-2 text-xs max-w-xs mx-2 order-2 items-start">
          <div>
            <span class="px-4 py-2 rounded-lg inline-block rounded-bl-none bg-gray-300 text-gray-600">
              <%= @message.content %>
            </span>     
          </div>
          <span class="text-xs text-gray-900/60"><%= humanize_datetime(@message.created_at) %></span>
        </div>
        <span class="w-6 h-6 rounded-full order-1 bg-gray-900 text-white text-center">R</span>
      </div>
    </div>
    """
  end

  defp bubble(%{direction: :sender} = assigns) do
    ~H"""
    <div {@rest}>
      <div class="flex items-end justify-end">
        <div class="flex flex-col space-y-2 text-xs max-w-xs mx-2 order-1 items-end">
          
          <div>
            <span class="px-4 py-2 rounded-lg inline-block rounded-bl-none bg-blue-600 text-white">
              <%= @message.content %>
            </span>
          </div>
          <span class="text-xs text-gray-900/60"><%= humanize_datetime(@message.created_at) %></span>
        </div>
        <span class="w-6 h-6 rounded-full order-1 bg-blue-900 text-white text-center">S</span>
      </div>
    </div>
    """
  end

  defp prepare_state(nil, socket) do
    socket
    |> put_flash(:error, "The room not found")
    |> push_navigate(to: ~p"/lobby")
  end

  defp prepare_state({id, _, _}, socket) do
    Rooms.add_user(id, socket.assigns.current_user)

    if connected?(socket) do
      Rooms.subscribe(id)
    end

    socket
    |> assign(:room_id, id)
    |> stream_configure(:users, dom_id: fn user -> user.id end)
    |> stream(:users, Rooms.list_users(id))
    |> stream_configure(:messages, dom_id: fn message -> message.id end)
    |> stream(:messages, Rooms.list_messages(id))
    |> assign(:form, to_form(%{"content" => ""}))
  end

  defp humanize_datetime(datetime) do
    Timex.diff(datetime, DateTime.utc_now(), :duration)
    |> Timex.format_duration(:humanized)
  end
end
