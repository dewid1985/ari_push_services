defmodule Ari.Schemas.Shared.Header do
  # Use Ecto.Schema to define the structure of the embedded schema
  use Ecto.Schema
  # Import Ecto.Changeset to work with changesets for validations, casting, and embedding schemas
  import Ecto.Changeset

  # Define an embedded schema, meaning it will be used within another schema and not as a separate table
  embedded_schema do
    # Define fields within the embedded schema
    field :action, :string  # A string field for the action (e.g., create, update, etc.)
    field :to, :string  # A string field representing the recipient or target of the message
    field :message_id, :string  # A string field for the message identifier

    # Define embedded schemas within this schema
    # `security` and `reply_to` are embedded schemas that refer to other modules
    embeds_one :security, Ari.Schemas.Shared.Security  # Embed the `Security` schema
    embeds_one :reply_to, Ari.Schemas.Shared.ReplyTo  # Embed the `ReplyTo` schema
  end

  # Define a changeset function to validate and cast incoming data into the `Header` schema
  def changeset(header, attrs) do
    header
    # Cast the attributes (passed in `attrs`) for the fields `:action`, `:to`, and `:message_id`
    |> cast(attrs, [:action, :to, :message_id])
      # Cast the embedded fields `:security` and `:reply_to` as they are nested schemas
    |> cast_embed(:security)
    |> cast_embed(:reply_to)
      # Ensure that the fields `:action`, `:to`, and `:message_id` are present and not empty
    |> validate_required([:action, :to, :message_id])
  end
end
