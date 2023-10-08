defmodule Chat.Rooms do
  use GenServer
  alias Chat.HexPuid
  alias Chat.Rooms.User
  alias Chat.Rooms.Message

  # server
  @impl true
  def init(:ok) do
    rooms = :ets.new(__MODULE__, [:set, :named_table])
    {:ok, rooms}
  end

  # sync

  @impl true
  def handle_call(:create, _from, rooms) do
    id = HexPuid.generate()
    :ets.insert(rooms, {id, [], []})
    {:reply, id, rooms}
  end

  @impl true
  def handle_call({:get, id, default}, _from, rooms) do
    room =
      case :ets.lookup(rooms, id) do
        [match | _] -> match
        [] -> default
      end

    {:reply, room, rooms}
  end

  @impl true
  def handle_call({:fetch, id}, _from, rooms) do
    room =
      case :ets.lookup(rooms, id) do
        [match | _] -> {:ok, match}
        [] -> :error
      end

    {:reply, room, rooms}
  end

  @impl true
  def handle_call({:remove_user, room, user}, _from ,rooms) do
    {id, users, messages} = room

    
    users =
      users
      |> Enum.reject(&(&1 == user))
    if Enum.empty?(users) do
      :ets.delete(rooms,id)
    else
      :ets.insert(rooms, {id, users, messages})
    end
    broadcast(id, {:user_disconnect, user})
    {:reply,user, rooms}
  end

  # async

  @impl true
  def handle_cast({:add_user, room, user}, rooms) do
    {id, users, messages} = room

    unless Enum.member?(users, user) do
      :ets.insert(rooms, {id, [user | users], messages})
      broadcast(id, {:user_connected, user})
    end

    {:noreply, rooms}
  end

  @impl true
  def handle_cast({:add_message, room, message}, rooms) do
    {id, users, messages} = room
    messages = [message | messages] |> Enum.reverse()
    :ets.insert(rooms, {id, users, messages})
    broadcast(id, {:message_sended, message})
    {:noreply, rooms}
  end

 
  @impl true
  def handle_cast({:delete_room, id}, rooms) do
    :ets.delete(rooms, id)
    {:noreply, rooms}
  end

  # client
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def create() do
    GenServer.call(__MODULE__, :create)
  end

  def get(id, default \\ nil) do
    GenServer.call(__MODULE__, {:get, id, default})
  end

  def fetch(id) do
    GenServer.call(__MODULE__, {:fetch, id})
  end

  def add_user(id, %User{} = user) do
    room = get(id)
    GenServer.cast(__MODULE__, {:add_user, room, user})
  end

  def add_message(id, %Message{} = message) do
    room = get(id)
    GenServer.cast(__MODULE__, {:add_message, room, message})
  end

  def remove_user(id, %User{} = user) do
    
    room = get(id)
    GenServer.call(__MODULE__, {:remove_user, room, user})
  end

  def delete_room(id) do
    GenServer.cast(__MODULE__, {:delete_room, id})
  end

  def list_users(id) do
    {_id, users, _messages} = get(id)
    users
  end

  def list_messages(id) do
    {_id, _users, messages} = get(id)
    messages
  end

  def subscribe(id) do
    Phoenix.PubSub.subscribe(Chat.PubSub, "room:#{id}")
  end

  def broadcast(id, {:user_connected, %User{}} = message) do
    Phoenix.PubSub.broadcast(Chat.PubSub, "room:#{id}", message)
  end

  def broadcast(id, {:user_disconnect, %User{}} = message) do
    Phoenix.PubSub.broadcast(Chat.PubSub, "room:#{id}", message)
  end

  def broadcast(id, {:message_sended, %Message{}} = message) do
    Phoenix.PubSub.broadcast(Chat.PubSub, "room:#{id}", message)
  end
end
