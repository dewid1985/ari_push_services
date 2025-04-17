defmodule Ari.Contexts.Inventory.OtaHotelInvCountNotifRQ do
  import Ecto.Query
  alias Ari.Repo
  alias Ari.Schemas.Inventory.{OtaHotelInvCountNotifRQ, Inventories}

  @doc """
  Returns all inventory notifications for the given hotel_code.
  """
  def get_inventory_by_hotel_code(hotel_code, customer_code) do
    base_query(hotel_code, customer_code)
    |> Repo.all()
  end

  @doc """
  Returns inventory notifications for the given hotel_code limited by the given limit.
  """
  def get_inventory_by_hotel_code(hotel_code, customer_code, limit) do
    base_query(hotel_code, customer_code)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Returns inventory notifications for the given hotel_code with pagination using limit and offset.
  """
  def get_inventory_by_hotel_code(hotel_code, customer_code, limit, offset) do
    base_query(hotel_code, customer_code)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  # Private function: Constructs the base query for retrieving inventory notifications.
  defp base_query(hotel_code, customer_code) do
    from notif in OtaHotelInvCountNotifRQ,
         join: inv in Inventories, on: notif.id == inv.ota_hotel_inv_count_notif_rq_id,
         where: inv.hotel_code == ^hotel_code and notif.customer_code == ^customer_code,
         preload: [inventories: {inv, [
           unique_id: [],
           inventory: [
             status_application_control: [:distination_system_codes],
             inv_counts: [inv_count: []]
           ]
         ]}],
         order_by: [asc: notif.time_stamp]
  end
end