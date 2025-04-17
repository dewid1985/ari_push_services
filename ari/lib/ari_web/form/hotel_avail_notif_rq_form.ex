defmodule AriWeb.Form.HotelAvailNotifRqForm do
  use Ecto.Schema
  alias Ari.Schemas.Availability.Update

  def changeset(%Update{} = avail_massage, attrs) do
    Update.changeset(avail_massage, attrs)
  end
end