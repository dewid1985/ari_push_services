defmodule Ari.Schemas.Availability.DestinationSystemCode do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "availability"

  schema "destination_system_code" do
    field :text, :string
    belongs_to :status_application_control, MyApp.Availability.StatusApplicationControl

    timestamps()
  end

  def changeset(destination_system_code, attrs) do
    destination_system_code
    |> cast(attrs, [:text])
    |> validate_required([:text])
  end
end