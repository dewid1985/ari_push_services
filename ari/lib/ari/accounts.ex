defmodule Ari.Accounts do
  use GenServer

  alias Ari.Repo
  alias Ari.Schemas.Users.{User, Role, Permission, Resource}
  import Bcrypt

  # Название ETS-таблицы
  @user_cache :user_cache

  # Функция для старта процесса и создания ETS таблицы
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Инициализация ETS таблицы при старте GenServer
  def init(_) do
    :ets.new(@user_cache, [:named_table, :set, :public])
    {:ok, %{}}
  end

  # Добавляем пользователя в ETS-кэш
  defp put_user_in_cache(email, user) do
    :ets.insert(@user_cache, {email, user})
  end

  # Получаем пользователя из ETS-кэша
  defp get_user_from_cache(email) do
    case :ets.lookup(@user_cache, email) do
      [{^email, user}] -> {:ok, user}
      [] -> {:error, :not_found}
    end
  end

  # Удаляем пользователя из ETS-кэша
  defp remove_user_from_cache(email) do
    :ets.delete(@user_cache, email)
  end

  # Аутентификация пользователя с использованием ETS для кэширования
  def authenticate_user(email, password) do
    # Сначала пытаемся найти пользователя в ETS-кэше
    case get_user_from_cache(email) do
      {:ok, user} ->
        # Если пользователь найден в ETS, проверяем его пароль
        if verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :unauthorized}
        end

      {:error, :not_found} ->
        # Если пользователя нет в ETS, ищем его в базе данных
        case Repo.get_by(User, email: email) do
          nil ->
            # Если пользователь не найден в базе данных, возвращаем ошибку
            {:error, :unauthorized}

          user ->
            # Если пользователь найден, проверяем пароль
            if verify_pass(password, user.password_hash) do
              # Если пароль корректный, сохраняем пользователя в ETS и возвращаем результат
              put_user_in_cache(email, user)
              {:ok, user}
            else
              {:error, :unauthorized}
            end
        end
    end
  end

  # Регистрация нового пользователя
  def register_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  # Создание роли
  def create_role(attrs) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
  end

  # Создание разрешения
  def create_permission(attrs) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> Repo.insert()
  end

  # Создание ресурса
  def create_resource(attrs) do
    %Resource{}
    |> Resource.changeset(attrs)
    |> Repo.insert()
  end
end
