defmodule ChatWeb.AuthController do
  use ChatWeb, :controller

  def login(conn, %{"name" => name}) do
    user = Chat.Rooms.User.create(name)

    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> put_session(:current_user, user)
    |> redirect(to: ~p"/lobby")
  end
end
