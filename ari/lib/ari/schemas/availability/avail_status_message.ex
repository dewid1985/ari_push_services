defmodule Ari.Schemas.Availability.AvailStatusMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "availability"

  schema "avail_status_message" do
    belongs_to :avail_status_messages, Ari.Schemas.Availability.AvailStatusMessages

    has_one :status_application_control, Ari.Schemas.Availability.StatusApplicationControl

    has_one :unique_id, Ari.Schemas.Availability.UniqueId

    has_one :restriction_status, Ari.Schemas.Availability.RestrictionStatus

    has_one :lengths_of_stay, Ari.Schemas.Availability.LengthsOfStay

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:avail_status_messages_id])
    |> cast_assoc(:status_application_control)
    |> cast_assoc(:unique_id)
    |> cast_assoc(:restriction_status)
    |> cast_assoc(:lengths_of_stay)
  end
end