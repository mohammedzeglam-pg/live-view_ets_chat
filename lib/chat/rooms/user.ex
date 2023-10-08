defmodule Chat.Rooms.User do
  @moduledoc """
      Active Record Pattern for `user` entity.
  """
  alias Chat.HexPuid

  defstruct [:id, :name]

  @doc """
  Create new `user` entity

  ## Examples
    iex> create("mohammed")
    %User{id: ..., name: "mohammed"}
  """
  def create(name) when is_binary(name) do
    struct!(%__MODULE__{}, id: HexPuid.generate(), name: name)
  end
end
