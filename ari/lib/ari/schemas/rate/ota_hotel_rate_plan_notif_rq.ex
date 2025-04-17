defmodule Ari.Schemas.Rate.OtaHotelRatePlanNotifRQ do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "rate"
  # Specifies the schema prefix (or database schema) where this table exists.
  # Useful if you're organizing tables under different schemas in your database.

  schema "ota_hotel_rate_plan_notif_rq" do
    # Defines the structure of the database table `ota_hotel_rate_plan_notif_rq`.

    field :time_stamp, :utc_datetime_usec
    # `:time_stamp` is an `utc_datetime` field for storing the timestamp of the message.

    field :version, :string
    # `:version` is a string field representing the version of the OTA message.

    field :message_content_code, :string
    # `:message_content_code` is a string field for the content code of the message,
    # indicating the type of content being sent.

    field :active, :boolean, default: true

    field :outside_id, :string
    field :message_id, :integer
    field :customer_code, :string

    has_one :rate_plans, Ari.Schemas.Rate.RatePlans
    # This defines a one-to-one relationship with the `rate_plans` schema.
    # It assumes that the related `Ari.Schemas.Rate.RatePlans` schema exists
    # and is properly set up to reference this schema.

    timestamps()
    # `timestamps/0` adds `inserted_at` and `updated_at` fields to the schema
    # for tracking when records are created and updated.
  end


  #Creates a changeset for `OtaHotelRatePlanNotifRQ` with given attributes.
  # - `message`: the current data (either new or existing) for the message.
  # `attrs`: the attributes being cast into the message schema.
  # Casts the following fields:
  # - `version` (string)
  # - `message_content_code` (string, optional)
  # - `time_stamp` (UTC datetime, required)
  # It also ensures that the `rate_plans` association is properly cast and validated.
  # Validations:
  # - `:version` and `:time_stamp` are required fields.
  # - The associated `rate_plans` must be present and valid (`required: true`).
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:version, :message_content_code, :time_stamp, :active, :customer_code, :message_id, :outside_id])
      # Casts the provided attributes (`attrs`) into the fields defined in the schema.

    |> validate_required([:version, :time_stamp])
      # Ensures that `version` and `time_stamp` are present and not `nil`.

    |> cast_assoc(:rate_plans)
    # Casts and validates the associated `rate_plans`.
    # `required: true` ensures that the `rate_plans` association must be provided.
  end
end
