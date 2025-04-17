defmodule Ari.Schemas.Shared.Pagination do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    # Default values: limit = 100, offset = 0
    field :limit, :integer
    field :offset, :integer
  end

  @doc """
  Creates a changeset for Pagination ensuring that:
    - :limit is present, is a positive integer, and its type is correct.
    - :offset is present, is a non-negative integer, and its type is correct.

  If casting fails (e.g., the value is not an integer), a custom error is added.
  """
  def changeset(pagination, attrs) do
    pagination
    |> cast(attrs, [:limit, :offset])
    |> validate_required([:limit, :offset])
    |> validate_number(:limit, greater_than: 0)
    |> validate_number(:offset, greater_than_or_equal_to: 0)
    |> put_custom_type_errors()
  end

  # Function to replace default cast errors with custom error messages.
  defp put_custom_type_errors(changeset) do
    # Find casting errors for :limit.
    limit_cast_error =
      Enum.find(changeset.errors, fn
        {:limit, {_, opts}} ->
          Keyword.get(opts, :validation) == :cast
        _ ->
          false
      end)

    # Find casting errors for :offset.
    offset_cast_error =
      Enum.find(changeset.errors, fn
        {:offset, {_, opts}} ->
          Keyword.get(opts, :validation) == :cast
        _ ->
          false
      end)

    # Remove default casting errors for these fields.
    new_errors =
      changeset.errors
      |> Enum.reject(fn
        {field, {_, opts}} when field in [:limit, :offset] ->
          Keyword.get(opts, :validation) == :cast
        _ ->
          false
      end)

    changeset = %{changeset | errors: new_errors}

    # Add custom error messages if a casting error was found.
    changeset =
      if limit_cast_error do
        add_error(changeset, :limit, "Limit must be an integer")
      else
        changeset
      end

    changeset =
      if offset_cast_error do
        add_error(changeset, :offset, "Offset must be an integer")
      else
        changeset
      end

    changeset
  end
end
