defmodule Pigeon.Rooms.Join do
  def can_join(:group, users) do
    true
  end

  def can_join(:chat, users) do
    length(Enum.uniq(users)) <= 2
  end

  def can_join(:secret, users) do
    can_join(:chat, users)
  end
end
