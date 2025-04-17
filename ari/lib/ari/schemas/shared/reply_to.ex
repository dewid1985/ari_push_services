defmodule Ari.Schemas.Shared.ReplyTo do
  use Ecto.Schema  # Import Ecto.Schema to define the embedded schema.
  import Ecto.Changeset  # Import Ecto.Changeset for handling changes and validations.

  # Define an embedded schema for the ReplyTo structure.
  embedded_schema do
    field :address, :string  # A string field representing the reply-to email address.
  end

  # Creates a changeset for the `ReplyTo` schema, validating the provided attributes.
  #
  # This function:
  # 1. Accepts the current `reply_to` struct and a map of attributes.
  # 2. Casts the attributes into the schema fields.
  # 3. Validates the presence of the required `address` field.
  def changeset(reply_to, attrs) do
    reply_to
    |> cast(attrs, [:address])  # Cast the provided attributes into the schema.
    |> validate_required([:address])  # Ensure that `address` is present.
  end
end
