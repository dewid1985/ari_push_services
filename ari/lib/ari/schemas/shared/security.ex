defmodule Ari.Schemas.Shared.Security do
  use Ecto.Schema  # Import Ecto.Schema to define the embedded schema for Security.
  import Ecto.Changeset  # Import Ecto.Changeset to handle changes and validations for the schema.

  # Define an embedded schema for the Security structure.
  embedded_schema do
    # This embeds a one-to-one relationship with the UserNameToken schema,
    # which typically contains authentication information for users.
    embeds_one :user_name_token, Ari.Schemas.Shared.UserNameToken
  end

  # Creates a changeset for the `Security` schema, validating the provided attributes.
  #
  # This function:
  # 1. Accepts the current `security` struct and a map of attributes.
  # 2. Casts the attributes into the schema fields.
  # 3. Processes the embedded `user_name_token`.
  def changeset(security, attrs) do
    security
    |> cast(attrs, [])  # No top-level fields to cast; it only contains an embedded structure.
    |> cast_embed(:user_name_token)  # Cast the embedded `user_name_token`, allowing its attributes to be processed.
  end
end
