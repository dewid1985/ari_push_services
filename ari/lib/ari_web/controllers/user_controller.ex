defmodule AriWeb.UserController do
  # This module is a Phoenix controller for handling user-related actions (registration, login, role/permission/resource creation)
  use AriWeb, :controller

  # Import relevant modules from the application context
  alias Ari.Accounts  # Handles user, role, permission, and resource logic
  alias Ari.Auth      # Handles authentication logic, such as JWT generation

  # Registers a new user
  def create(conn, %{"email" => email, "password" => password, "customer_code" => customer_code}) do
    case Accounts.register_user(%{"email" => email, "password" => password, "customer_code" => customer_code}) do
      {:ok, user} ->
        # If registration is successful, return HTTP 201 Created with user info
        conn
        |> put_status(:created)
        |> json(%{message: "User created", user: user})

      {:error, changeset} ->
        # If registration fails due to validation errors, return HTTP 422 Unprocessable Entity with translated errors
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})
    end
  end

  # Authenticates an existing user using email and password
  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        # On successful authentication, generate JWT and return it
        token = Auth.generate_jwt(user)
        conn
        |> put_status(:ok)
        |> json(%{token: token})

      {:error, :unauthorized} ->
        # On failed authentication, return HTTP 401 Unauthorized with error message
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid credentials"})
    end
  end

  # Creates a new role
  def create_role(conn, %{"name" => name, "parent_role_id" => parent_role_id}) do
    case Accounts.create_role(%{"name" => name, "parent_role_id" => parent_role_id}) do
      {:ok, role} ->
        # If role creation succeeds, return HTTP 201 with the new role
        conn
        |> put_status(:created)
        |> json(%{message: "Role created", role: role})

      {:error, changeset} ->
        # On validation failure, return 422 with raw changeset errors (could be improved with translation)
        conn
        |> put_status(:unprocessable_entity)
        |> json(changeset.errors)
    end
  end

  # Creates a new permission for a given resource
  def create_permission(conn, %{"action" => action, "resource_id" => resource_id}) do
    case Accounts.create_permission(%{"action" => action, "resource_id" => resource_id}) do
      {:ok, permission} ->
        # On success, return the created permission with HTTP 201
        conn
        |> put_status(:created)
        |> json(%{message: "Permission created", permission: permission})

      {:error, changeset} ->
        # Return validation errors with 422
        conn
        |> put_status(:unprocessable_entity)
        |> json(changeset.errors)
    end
  end

  # Creates a new resource (could be an API endpoint, page, etc.)
  def create_resource(conn, %{"name" => name, "description" => description, "url" => url}) do
    case Accounts.create_resource(%{"name" => name, "description" => description, "url" => url}) do
      {:ok, resource} ->
        # Return the newly created resource
        conn
        |> put_status(:created)
        |> json(%{message: "Resource created", resource: resource})

      {:error, changeset} ->
        # Return validation errors on failure
        conn
        |> put_status(:unprocessable_entity)
        |> json(changeset.errors)
    end
  end

  # Translates Ecto validation errors into human-readable format
  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      # Replace placeholders (e.g., %{count}) with actual values from opts
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
