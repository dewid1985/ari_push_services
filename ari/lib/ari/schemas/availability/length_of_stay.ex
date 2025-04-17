defmodule Ari.Schemas.Availability.LengthOfStay do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "availability"

  schema "length_of_stay" do
    field :time, :string
    field :time_unit, :string
    field :min_max_message_type, :string

    belongs_to :lengths_of_stay, MyApp.Availability.LengthsOfStay

    timestamps()
  end

  def changeset(length_of_stay_item, attrs) do
    length_of_stay_item
    |> cast(attrs, [:time, :time_unit, :min_max_message_type])
    |> validate_required([:time, :time_unit, :min_max_message_type])
  end
end