defmodule  Ari.Schemas.Availability.RestrictionStatus do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "availability"

  schema "restriction_status" do
    field :restriction, :string
    field :status, :string
    field :max_advanced_booking_offset, :string
    field :min_advanced_booking_offset, :string

    belongs_to :avail_status_message, Ari.Schemas.Availability.AvailStatusMessage

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :restriction,
      :status,
      :max_advanced_booking_offset,
      :min_advanced_booking_offset,
      :avail_status_message_id
    ])
  end
end