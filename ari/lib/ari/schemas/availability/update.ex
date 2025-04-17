defmodule Ari.Schemas.Availability.Update do
  use Ecto.Schema  # Import the Ecto.Schema module to define a schema.
  import Ecto.Changeset  # Import Ecto.Changeset for working with changesets.

  # Define the embedded schema for the RateMessage.
  embedded_schema do
    # Embed one schema for the header of the rate message.
    embeds_one :header, Ari.Schemas.Shared.Header

    # Embed one schema for the body of the rate message.
    embeds_one :body, Ari.Schemas.Availability.UpdateBody
  end

  # Function to create a changeset for the RateMessage schema.
  # This function takes the current state of the RateMessage struct and the incoming attributes.
  #
  # Parameters:
  # - `rate_message`: The current state of the RateMessage struct.
  # - `attrs`: A map of incoming attributes to apply to the RateMessage.
  #
  # Returns:
  # A changeset that contains the changes and validations.
  def changeset(rate_message, attrs) do
    rate_message
    |> cast(attrs, [])  # Cast attributes to the RateMessage, but no top-level fields are specified.
    |> cast_embed(:header, required: true)  # Require the header to be present in the changeset.
    |> cast_embed(:body, required: true)    # Require the body to be present in the changeset.
  end
end
