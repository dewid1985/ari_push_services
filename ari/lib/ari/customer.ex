defmodule MyApp.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customer" do
    field :name, :string
    field :code, :string
    field :active, :boolean

    timestamps()

    has_one :user, MyApp.User
  end

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:name, :code, :active])
    |> validate_required([:name, :code, :active])
    |> validate_length(:name, min: 8, max: 255)
    |> validate_length(:code, min: 8, max: 255)
    |> validate_inclusion(:active, [true, false])
  end
end