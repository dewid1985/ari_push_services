defmodule Ari.Schemas.Availability.LengthsOfStay do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "availability"

  schema "lengths_of_stay" do
    field :fixed_pattern_length, :string

    belongs_to :avail_status_message, MyApp.Availability.AvailStatusMessage

    has_many :length_of_stay, Ari.Schemas.Availability.LengthOfStay

    timestamps()
  end

  def changeset(lengths_of_stay, attrs) do
    lengths_of_stay
    |> cast(attrs, [:fixed_pattern_length])
    |> cast_assoc(:length_of_stay)
  end
end