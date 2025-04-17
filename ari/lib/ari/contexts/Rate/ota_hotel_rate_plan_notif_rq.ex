defmodule Ari.Contexts.Rate.OtaHotelRatePlanNotifRQ do
  import Ecto.Query
  alias Ari.Repo
  alias Ari.Schemas.Rate.{OtaHotelRatePlanNotifRQ, RatePlans}

  def get_rate_plan_by_hotel_code(hotel_code, customer_code) do
    base_query(hotel_code, customer_code)
    |> Repo.all()
  end

  def get_rate_plan_by_hotel_code(hotel_code, customer_code,limit) do
    base_query(hotel_code, customer_code)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_rate_plan_by_hotel_code(hotel_code, customer_code, limit, offset) do
    query = base_query(hotel_code, customer_code)
            |> limit(^limit)
            |> offset(^offset)

    {sql, params} = Ecto.Adapters.SQL.to_sql(:all, Repo, query)

    query |> Repo.all()
  end

  defp base_query(hotel_code, customer_code) do
    from notif in OtaHotelRatePlanNotifRQ,
         join: rp in RatePlans, on: notif.id == rp.ota_hotel_rate_plan_notif_rq_id,
         where: rp.hotel_code == ^hotel_code and notif.customer_code == ^customer_code,
         preload: [
           rate_plans: {rp, [
             rate_plan: [
               :unique_id,
               :destination_systems_code,
               rates: [
                 base_by_guest_amts: []
               ]
             ]
           ]}
         ],
         order_by: [asc: notif.time_stamp]
  end
end
