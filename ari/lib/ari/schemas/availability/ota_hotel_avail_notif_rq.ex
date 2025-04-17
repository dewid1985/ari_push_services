defmodule Ari.Schemas.Availability.OtaHotelAvailNotifRq do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "availability"

  schema "ota_hotel_avail_notif_rq" do
    field :time_stamp, :utc_datetime_usec
    field :version, :string
    field :message_content_code, :string
    field :outside_id, :string
    field :message_id, :integer
    field :customer_code, :string
    field :active, :boolean, default: true

    # Связь с контейнером AvailStatusMessages
    has_one :avail_status_messages, Ari.Schemas.Availability.AvailStatusMessages

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:time_stamp, :version, :message_content_code, :active, :outside_id, :message_id, :customer_code])
    |> validate_required([:time_stamp, :version])
    |> cast_assoc(:avail_status_messages)
  end
end
