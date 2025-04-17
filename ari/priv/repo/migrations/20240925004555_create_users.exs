defmodule Ari.Repo.Migrations.CreateUsersRolesPermissions do
  use Ecto.Migration

  def change do
    # Create the 'users' schema if it does not exist
    execute "CREATE SCHEMA IF NOT EXISTS users"

    # Users table to store user information
    create table(:users, prefix: "users") do
      add :email, :string, null: false  # User's email address
      add :password_hash, :string, null: false  # Hashed password for authentication
      add :customer_code, :string, null: false

      timestamps()  # Automatically adds inserted_at and updated_at fields
    end

    # Unique index on the email field to ensure no duplicate emails
    create unique_index(:users, [:email], prefix: "users")

    # Roles table to define different user roles
    create table(:roles, prefix: "users") do
      add :name, :string, null: false  # Name of the role (e.g., admin, user)
      add :parent_role_id, references(:roles, on_delete: :nilify_all, prefix: "users")  # Reference to a parent role for role inheritance

      timestamps()  # Automatically adds inserted_at and updated_at fields
    end

    # Unique index on the name field to prevent duplicate role names
    create unique_index(:roles, [:name], prefix: "users")

    # Resources table to define various resources the system manages
    create table(:resources, prefix: "users") do
      add :name, :string, null: false  # Name of the resource (e.g., articles, comments)
      add :description, :string  # Description of the resource
      add :url, :string, null: false  # URL or path for accessing the resource

      timestamps()  # Automatically adds inserted_at and updated_at fields
    end

    # Unique index on the name field to ensure no duplicate resource names
    create unique_index(:resources, [:name], prefix: "users")

    # Permissions table to define actions that can be performed on resources
    create table(:permissions, prefix: "users") do
      add :action, :string, null: false  # Action: create, read, update, delete, etc.
      add :resource_id, references(:resources, on_delete: :delete_all, prefix: "users")  # Reference to the resource on which the action can be performed

      timestamps()  # Automatically adds inserted_at and updated_at fields
    end

    # Unique index on action and resource_id to ensure no duplicate permissions
    create unique_index(:permissions, [:action, :resource_id], prefix: "users")

    # Join table to associate users with roles
    create table(:user_roles, prefix: "users") do
      add :user_id, references(:users, on_delete: :delete_all, prefix: "users")  # Reference to the user
      add :role_id, references(:roles, on_delete: :delete_all, prefix: "users")  # Reference to the role

      timestamps()  # Automatically adds inserted_at and updated_at fields
    end

    # Unique index on user_id and role_id to ensure no duplicate user-role associations
    create unique_index(:user_roles, [:user_id, :role_id], prefix: "users")

    # Join table to associate roles with permissions
    create table(:role_permissions, prefix: "users") do
      add :role_id, references(:roles, on_delete: :delete_all, prefix: "users")  # Reference to the role
      add :permission_id, references(:permissions, on_delete: :delete_all, prefix: "users")  # Reference to the permission

      timestamps()  # Automatically adds inserted_at and updated_at fields
    end

    # Unique index on role_id and permission_id to prevent duplicate role-permission associations
    create unique_index(:role_permissions, [:role_id, :permission_id], prefix: "users")

    # Join table for unique permissions assigned directly to users
    create table(:user_permissions, prefix: "users") do
      add :user_id, references(:users, on_delete: :delete_all, prefix: "users")  # Reference to the user
      add :permission_id, references(:permissions, on_delete: :delete_all, prefix: "users")  # Reference to the permission

      timestamps()  # Automatically adds inserted_at and updated_at fields
    end

    # Unique index on user_id and permission_id to ensure no duplicate user-permission associations
    create unique_index(:user_permissions, [:user_id, :permission_id], prefix: "users")
  end
end
