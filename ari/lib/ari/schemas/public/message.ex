defmodule Ari.Schemas.Public.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :entity_id, :integer
    field :hotel_code, :string
    field :double, :boolean, default: false
    field :error, :boolean, default: false
    field :user_name, :string
    field :rate, :boolean, default: false
    field :availability, :boolean, default: false
    field :inventory, :boolean, default: false
    field :time_stamp, :naive_datetime_usec
    field :internal_id, :string
    field :outside_id, :string
    field :customer_code, :string
    field :active, :boolean, default: true
    field :checksum, :string
    field :request, :string
    field :response, :string
    field :deleted_at, :utc_datetime

    timestamps()
  end

  # Changeset для валидации и приведения параметров
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:entity_id, :hotel_code, :double, :error, :user_name, :rate, :availability, :inventory, :time_stamp, :internal_id, :outside_id, :customer_code, :active, :checksum, :request, :response, :deleted_at])
    |> validate_required([:hotel_code, :user_name, :time_stamp])
  end
end