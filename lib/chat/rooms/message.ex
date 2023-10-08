defmodule Chat.Rooms.Message do
  @moduledoc """
      Active Record pattern for `message` entity.
  """
  alias Chat.HexPuid
  defstruct [:id, :user_id, :content, :created_at]

  def create(%{content: content, user_id: user_id}) do
    id = HexPuid.generate()
    created_at = DateTime.utc_now()
    struct!(%__MODULE__{}, id: id, user_id: user_id, content: content, created_at: created_at)
  end
end
