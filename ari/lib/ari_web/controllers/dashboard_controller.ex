defmodule AriWeb.DashboardController do
  use AriWeb, :controller

  import Ecto.Query

  alias Ari.Accounts
  alias Ari.Repo
  alias Ari.Schemas.Public.Message
  alias Ari.Schemas.Users.User

  def index(conn, _params) do
    redirect(conn, to: "/viewer/index.html?draw=1&length=10&active=true&start=0")
  end

  def viewer_index(conn, _params) do
    redirect(conn, to: "/viewer/index.html")
  end

  def messages(conn, params) do
    messages =
      Message
      |> apply_message_filters(params)
      |> order_by([m], desc: m.inserted_at)
      |> limit(500)
      |> Repo.all()
      |> Enum.map(&message_json/1)

    json(conn, %{data: messages})
  end

  def update_messages(conn, params) do
    active = truthy?(Map.get(params, "active"))

    {count, _} =
      Message
      |> apply_message_filters(params)
      |> Repo.update_all(set: [active: active])

    json(conn, %{updated: count, active: active})
  end

  def users(conn, params) do
    users =
      User
      |> apply_user_filters(params)
      |> order_by([u], desc: u.inserted_at)
      |> limit(500)
      |> Repo.all()
      |> Enum.map(&user_json/1)

    json(conn, %{data: users})
  end

  def create_user(conn, params) do
    attrs = %{
      "email" => Map.get(params, "email") || Map.get(params, "username"),
      "password" => Map.get(params, "password"),
      "customer_code" => Map.get(params, "customer_code") || Map.get(params, "customerCode")
    }

    case Accounts.register_user(attrs) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{user: user_json(user)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})
    end
  end

  def viewer_messages(conn, params) do
    query = apply_message_filters(Message, legacy_message_params(params))
    total = Repo.aggregate(Message, :count, :id)
    filtered = Repo.aggregate(query, :count, :id)

    data =
      query
      |> order_by([m], desc: m.inserted_at)
      |> offset(^data_table_start(params))
      |> limit(^data_table_length(params))
      |> Repo.all()
      |> Enum.map(&legacy_message_json/1)

    json(conn, data_table_response(params, total, filtered, data))
  end

  def viewer_update_messages(conn, params) do
    active = !truthy?(Map.get(params, "active"))

    {count, _} =
      Message
      |> apply_message_filters(legacy_message_params(params))
      |> Repo.update_all(set: [active: active])

    json(conn, %{success: true, updated: count, active: active})
  end

  def viewer_users(conn, params) do
    query = apply_user_filters(User, legacy_user_params(params))
    total = Repo.aggregate(User, :count, :id)
    filtered = Repo.aggregate(query, :count, :id)

    data =
      query
      |> order_by([u], desc: u.inserted_at)
      |> offset(^data_table_start(params))
      |> limit(^data_table_length(params))
      |> Repo.all()
      |> Enum.map(&legacy_user_json/1)

    json(conn, data_table_response(params, total, filtered, data))
  end

  def viewer_create_user(conn, params), do: legacy_create_user(conn, params)
  def viewer_delete_user(conn, %{"id" => id}), do: legacy_delete_user(conn, %{"id" => id})

  def viewer_payload(conn, %{"action" => action, "id" => id}) when action in ["request", "response"] do
    message = Repo.get(Message, id)
    payload = if message, do: Map.get(message, String.to_existing_atom(action)), else: nil

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(if(payload, do: 200, else: 404), payload || "Not found")
  end

  def viewer_payload(conn, _params) do
    redirect(conn, to: "/viewer/index.html")
  end

  def legacy_index(conn, %{"action" => "getUsers"} = params) do
    query = apply_user_filters(User, legacy_user_params(params))
    total = Repo.aggregate(User, :count, :id)
    filtered = Repo.aggregate(query, :count, :id)

    data =
      query
      |> order_by([u], desc: u.inserted_at)
      |> offset(^data_table_start(params))
      |> limit(^data_table_length(params))
      |> Repo.all()
      |> Enum.map(&legacy_user_json/1)

    json(conn, data_table_response(params, total, filtered, data))
  end

  def legacy_index(conn, %{"action" => "createUser"} = params), do: legacy_create_user(conn, params)
  def legacy_index(conn, %{"action" => "deleteUser"} = params), do: legacy_delete_user(conn, params)

  def legacy_index(conn, %{"action" => "deactivate"} = params) do
    active = !truthy?(Map.get(params, "active"))

    {count, _} =
      Message
      |> apply_message_filters(legacy_message_params(params))
      |> Repo.update_all(set: [active: active])

    json(conn, %{success: true, updated: count, active: active})
  end

  def legacy_index(conn, params) do
    query = apply_message_filters(Message, legacy_message_params(params))
    total = Repo.aggregate(Message, :count, :id)
    filtered = Repo.aggregate(query, :count, :id)

    data =
      query
      |> order_by([m], desc: m.inserted_at)
      |> offset(^data_table_start(params))
      |> limit(^data_table_length(params))
      |> Repo.all()
      |> Enum.map(&legacy_message_json/1)

    json(conn, data_table_response(params, total, filtered, data))
  end

  defp apply_message_filters(query, params) do
    query
    |> maybe_where_id(Map.get(params, "id"))
    |> maybe_where_like(:hotel_code, Map.get(params, "hotel_code"))
    |> maybe_where_like(:checksum, Map.get(params, "checksum"))
    |> maybe_where_like(:user_name, Map.get(params, "user_name"))
    |> maybe_where_like(:outside_id, Map.get(params, "outside_id"))
    |> maybe_where_like(:internal_id, Map.get(params, "internal_id"))
    |> maybe_where_type(Map.get(params, "type"))
    |> maybe_where_bool(:double, Map.get(params, "double"))
    |> maybe_where_bool(:error, Map.get(params, "error"))
    |> maybe_where_bool(:active, Map.get(params, "active"))
    |> maybe_where_datetime(:time_stamp, :>=, Map.get(params, "time_from"))
    |> maybe_where_datetime(:time_stamp, :<=, Map.get(params, "time_to"))
    |> maybe_where_datetime(:inserted_at, :>=, Map.get(params, "created_from"))
    |> maybe_where_datetime(:inserted_at, :<=, Map.get(params, "created_to"))
    |> maybe_where_datetime(:updated_at, :>=, Map.get(params, "updated_from"))
    |> maybe_where_datetime(:updated_at, :<=, Map.get(params, "updated_to"))
  end

  defp maybe_where_id(query, value) when value in [nil, ""], do: query

  defp maybe_where_id(query, value) do
    case Integer.parse(to_string(value)) do
      {id, ""} -> where(query, [r], r.id == ^id)
      _ -> query
    end
  end

  defp apply_user_filters(query, params) do
    query
    |> maybe_where_like(:email, Map.get(params, "email"))
    |> maybe_where_like(:customer_code, Map.get(params, "customer_code"))
  end

  defp legacy_create_user(conn, params) do
    attrs = %{
      "email" => Map.get(params, "username"),
      "password" => Map.get(params, "password"),
      "customer_code" => Map.get(params, "customerCode")
    }

    case Accounts.register_user(attrs) do
      {:ok, _user} ->
        json(conn, %{success: true})

      {:error, changeset} ->
        json(conn, %{success: false, errors: legacy_user_errors(changeset)})
    end
  end

  defp legacy_delete_user(conn, %{"id" => id}) do
    with {id, ""} <- Integer.parse(to_string(id)),
         %User{} = user <- Repo.get(User, id),
         {:ok, _user} <- Repo.delete(user) do
      json(conn, %{success: true})
    else
      _ -> json(conn, %{success: false})
    end
  end

  defp legacy_delete_user(conn, _params), do: json(conn, %{success: false})

  defp legacy_message_params(params) do
    %{
      "hotel_code" => Map.get(params, "hotelCode"),
      "type" => Map.get(params, "type"),
      "checksum" => Map.get(params, "checksum"),
      "user_name" => Map.get(params, "user"),
      "outside_id" => Map.get(params, "outsideId"),
      "internal_id" => Map.get(params, "internalId"),
      "time_from" => Map.get(params, "startDate"),
      "time_to" => Map.get(params, "endDate"),
      "created_from" => Map.get(params, "startCreatedAt"),
      "created_to" => Map.get(params, "endCreatedAt"),
      "updated_from" => Map.get(params, "startUpdatedAt"),
      "updated_to" => Map.get(params, "endUpdatedAt"),
      "double" => checked_param(params, "double"),
      "error" => checked_param(params, "error"),
      "active" => checked_param(params, "active")
    }
  end

  defp legacy_user_params(params) do
    %{
      "email" => Map.get(params, "name"),
      "customer_code" => Map.get(params, "customerCode")
    }
  end

  defp checked_param(params, key) do
    case Map.get(params, key) do
      "true" -> "true"
      true -> "true"
      _ -> ""
    end
  end

  defp data_table_response(params, total, filtered, data) do
    %{
      draw: data_table_draw(params),
      recordsTotal: total,
      recordsFiltered: filtered,
      data: data
    }
  end

  defp data_table_draw(params) do
    params |> Map.get("draw", "1") |> parse_int(1)
  end

  defp data_table_start(params) do
    params |> Map.get("start", "0") |> parse_int(0)
  end

  defp data_table_length(params) do
    params |> Map.get("length", "10") |> parse_int(10)
  end

  defp parse_int(value, default) do
    case Integer.parse(to_string(value)) do
      {int, ""} -> int
      _ -> default
    end
  end

  defp maybe_where_like(query, _field, value) when value in [nil, ""], do: query

  defp maybe_where_like(query, field, value) do
    pattern = "%#{value}%"
    where(query, [r], ilike(field(r, ^field), ^pattern))
  end

  defp maybe_where_type(query, type) when type in [nil, ""], do: query
  defp maybe_where_type(query, "rate"), do: where(query, [m], m.rate == true)
  defp maybe_where_type(query, "availability"), do: where(query, [m], m.availability == true)
  defp maybe_where_type(query, "inventory"), do: where(query, [m], m.inventory == true)
  defp maybe_where_type(query, _type), do: query

  defp maybe_where_bool(query, _field, value) when value in [nil, ""], do: query

  defp maybe_where_bool(query, field, value) do
    where(query, [r], field(r, ^field) == ^truthy?(value))
  end

  defp maybe_where_datetime(query, _field, _op, value) when value in [nil, ""], do: query

  defp maybe_where_datetime(query, field, op, value) do
    with {:ok, datetime} <- parse_datetime(value) do
      case op do
        :>= -> where(query, [r], field(r, ^field) >= ^datetime)
        :<= -> where(query, [r], field(r, ^field) <= ^datetime)
      end
    else
      _ -> query
    end
  end

  defp parse_datetime(value) do
    value
    |> String.replace("T", " ")
    |> then(fn value ->
      cond do
        String.length(value) == 16 -> value <> ":00"
        true -> value
      end
    end)
    |> NaiveDateTime.from_iso8601()
  end

  defp truthy?(value), do: value in [true, "true", "1", 1, "on"]

  defp message_json(message) do
    %{
      id: message.id,
      entity_id: message.entity_id,
      hotel_code: message.hotel_code,
      type: message_type(message),
      double: message.double,
      error: message.error,
      active: message.active,
      user_name: message.user_name,
      checksum: message.checksum,
      internal_id: message.internal_id,
      outside_id: message.outside_id,
      customer_code: message.customer_code,
      time_stamp: format_datetime(message.time_stamp),
      inserted_at: format_datetime(message.inserted_at),
      updated_at: format_datetime(message.updated_at)
    }
  end

  defp user_json(user) do
    %{
      id: user.id,
      email: user.email,
      customer_code: user.customer_code,
      inserted_at: format_datetime(user.inserted_at)
    }
  end

  defp legacy_message_json(message) do
    %{
      id: message.id,
      code: message.hotel_code,
      checksum: message.checksum,
      user: message.user_name,
      time_stamp: format_datetime(message.time_stamp),
      outside_id: message.outside_id,
      created_at: format_datetime(message.inserted_at),
      updated_at: format_datetime(message.updated_at),
      internal_id: message.internal_id,
      double: legacy_bool(message.double),
      error: legacy_bool(message.error),
      active: legacy_bool(message.active),
      rate: legacy_bool(message.rate),
      inventory: legacy_bool(message.inventory),
      availability: legacy_bool(message.availability)
    }
  end

  defp legacy_user_json(user) do
    %{
      id: user.id,
      name: user.email,
      code: user.customer_code,
      created_at: format_datetime(user.inserted_at)
    }
  end

  defp legacy_bool(true), do: "t"
  defp legacy_bool(_), do: "f"

  defp legacy_user_errors(changeset) do
    errors = translate_errors(changeset)

    %{
      username: errors[:email] && Enum.join(errors[:email], ", "),
      password: errors[:password] && Enum.join(errors[:password], ", "),
      customerCode: errors[:customer_code] && Enum.join(errors[:customer_code], ", ")
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp message_type(%{rate: true}), do: "rate"
  defp message_type(%{availability: true}), do: "availability"
  defp message_type(%{inventory: true}), do: "inventory"
  defp message_type(_message), do: "unknown"

  defp format_datetime(nil), do: nil
  defp format_datetime(%NaiveDateTime{} = value), do: NaiveDateTime.to_string(value)
  defp format_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
