defmodule Ari.Schemas.Shared.UserNameToken do
  use Ecto.Schema  # Use Ecto.Schema to define the schema for UserNameToken.
  import Ecto.Changeset  # Import Ecto.Changeset to handle changes and validations.

  # Define an embedded schema to represent a user's authentication token details.
  embedded_schema do
    field :password, :string  # Field for the user's password.
    field :user_name, :string  # Field for the user's username (expected to be an email).
  end

  # Creates a changeset for the `UserNameToken` schema, validating the provided attributes.
  #
  # This function:
  # 1. Accepts the current `user_name_token` struct and a map of attributes.
  # 2. Casts the attributes into the schema fields.
  # 3. Validates the presence of required fields.
  # 4. Applies custom validations for username and password.
  def changeset(user_name_token, attrs) do
    user_name_token
    |> cast(attrs, [:password, :user_name])  # Cast only the `password` and `user_name` fields from the incoming attributes.
    |> validate_required([:password, :user_name])  # Ensure both fields are present in the changeset.
    |> validate_user_name()  # Custom validation for user_name.
    |> validate_password()    # Custom validation for password.
  end

  # Validates the correctness of the user_name (e.g., checks if it’s a valid email).
  defp validate_user_name(changeset) do
    user_name = get_field(changeset, :user_name)

    # Validate user_name against an email pattern (basic check).
    if user_name && !valid_email?(user_name) do
      add_error(changeset, :user_name, "244|Email address is invalid")  # Add error if user_name is not a valid email.
    else
      changeset  # Return the changeset if validation passes.
    end
  end

  # Validates the password for certain criteria (e.g., minimum length).
  defp validate_password(changeset) do
    password = get_field(changeset, :password)

    # Check the length of the password.
    if password && String.length(password) < 6 do
      add_error(changeset, :password, "174|Password is invalid (must be at least 6 characters)")  # Add error if password is too short.
    else
      changeset  # Return the changeset if validation passes.
    end
  end

  # Validates the format of the email (user_name).
  defp valid_email?(email) do
    # Basic email validation logic. Consider using a more robust regex or a library for comprehensive validation.
    String.contains?(email, "@") && String.contains?(email, ".")  # Simple check to ensure '@' and '.' are present.
  end
end
