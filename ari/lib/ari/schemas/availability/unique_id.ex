defmodule Ari.Schemas.Availability.UniqueId do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "availability"

  schema "unique_id" do
    field :code, :string
    field :type, :string

    belongs_to :avail_status_message, Ari.Schemas.Availability.AvailStatusMessage
    timestamps()
  end

  def changeset(unique_id, attrs) do
    unique_id
    |> cast(attrs, [:type, :code])
    |> validate_required([:type, :code])
  end
end