defmodule PublicRateParserRequest do
  import SweetXml

  @doc """
  Returns a map of XML namespaces used in the document.

  These namespaces are required for correctly parsing the elements
  that are associated with specific XML namespaces in the SOAP envelope.
  """
  def namespaces do
    %{
      "soap" => "http://www.w3.org/2003/05/soap-envelope", # SOAP envelope namespace
      "wsa" => "http://www.w3.org/2005/08/addressing",     # WS-Addressing namespace
      "wss" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd", # WS-Security namespace
      "ota" => "http://www.opentravel.org/OTA/2003/05"     # OpenTravel Alliance namespace
    }
  end

  @doc """
  Function to parse the given XML string.

  It processes the XML document using SweetXml with the defined namespaces
  and extracts relevant data like header and body elements, including
  hotel rate plan notifications (OTA_HotelRatePlanNotifRQ).
  """
  def parse(xml) when is_binary(xml) do

    # Parse the XML string with namespace conformance enabled to correctly handle namespaces.
    xml
    |> SweetXml.parse(namespace_conformant: true)

      # Start parsing from the root element, the SOAP Envelope.
    |> xpath(
         ~x"//soap:Envelope" |> add_namespace("soap", namespaces()["soap"]),

         # Extract and parse the SOAP Header section.
         header: [
           # Select the SOAP Header.
           ~x"//soap:Header" |> add_namespace("soap", namespaces()["soap"]),

           # Extract the WS-Addressing Action element (contains action details).
           action: ~x"//wsa:Action/text()"s |> add_namespace("wsa", namespaces()["wsa"]),

           # Extract the WS-Addressing ReplyTo element (includes reply address).
           reply_to: [
             ~x"//wsa:ReplyTo" |> add_namespace("wsa", namespaces()["wsa"]),

             # Extract the Address element from the ReplyTo section.
             address: ~x".//wsa:Address/text()"s |> add_namespace("wsa", namespaces()["wsa"])
           ],

           # Extract the WS-Security section.
           security: [
             ~x"//wss:Security" |> add_namespace("wss", namespaces()["wss"]),

             # Extract the UsernameToken for authentication information.
             user_name_token: [
               ~x"//wss:UsernameToken" |> add_namespace("wss", namespaces()["wss"]),

               # Extract the Username and Password (authentication details).
               user_name: ~x"//wss:Username/text()"s |> add_namespace("wss", namespaces()["wss"]),
               password: ~x"//wss:Password/text()"s |> add_namespace("wss", namespaces()["wss"])
             ]
           ],

           # Extract the MessageID (unique ID of the message) and To (destination address).
           message_id: ~x"//wsa:MessageID/text()"s |> add_namespace("wsa", namespaces()["wsa"]),
           to: ~x"//wsa:To/text()"s |> add_namespace("wsa", namespaces()["wsa"])
         ],

         # Extract and parse the SOAP Body section.
         body: [
           ~x"//soap:Body" |> add_namespace("soap", namespaces()["soap"]),

           # Extract the OTA_HotelRatePlanNotifRQ message (root element of the OTA rate plan notification).
           ota_hotel_rate_plan_notif_rq: [
             ~x"//ota:OTA_HotelRatePlanNotifRQ" |> add_namespace("ota", namespaces()["ota"]),

             # Extract attributes of the OTA_HotelRatePlanNotifRQ message.
             time_stamp: ~x"//@TimeStamp"s,            # Extract the timestamp of the message.
             version: ~x".//@Version"s,                # Extract the version of the OTA message.
             message_content_code: ~x"//@MessageContentCode"s, # Extract the content code.

             # Extract the RatePlans section within the OTA_HotelRatePlanNotifRQ message.
             rate_plans: [
               ~x"./ota:RatePlans" |> add_namespace("ota", namespaces()["ota"]),
               hotel_code: ~x"./@HotelCode"s,  # Extract the hotel code from the RatePlans.

               # Extract each RatePlan element within RatePlans.
               rate_plan: [
                 ~x"./ota:RatePlan"el |> add_namespace("ota", namespaces()["ota"]),
                 rate_plan_code: ~x"./@RatePlanCode"s,  # Extract the rate plan code.
                 rate_plan_notif_type: ~x"./@RatePlanNotifType"s,  # Extract the rate plan notification type.
                 start: ~x"./@Start"s,  # Extract the start date of the rate plan.
                 end: ~x"./@End"s,  # Extract the end date of the rate plan.

                 # Extract the DestinationSystemsCode section within each RatePlan.
                 destination_systems_code: [
                   ~x"./ota:DestinationSystemsCode/ota:DestinationSystemCode"el |> add_namespace("ota", namespaces()["ota"]),
                     text: ~x"./text()"s  # Extract the actual destination system code.

                 ],

                 # Extract the Rates section within each RatePlan.
                 rates: [
                   ~x"./ota:Rates/ota:Rate"el |> add_namespace("ota", namespaces()["ota"]),
                     currency_code: ~x"./@CurrencyCode"s,  # Extract the currency code for the rate.
                     inv_type_code: ~x"./@InvTypeCode"s,  # Extract the inventory type code.
                     rate_time_unit: ~x"./@RateTimeUnit"s, # Extract the rate time unit.
                     min_los: ~x"./@MinLOS"s,              # Extract the minimum length of stay.
                     max_los: ~x"./@MaxLOS"s,              # Extract the maximum length of stay.
                     mon: ~x"./@Mon"s,                     # Extract availability for Monday.
                     tue: ~x"./@Tue"s,                     # Extract availability for Tuesday.
                     weds: ~x"./@Weds"s,                   # Extract availability for Wednesday.
                     thur: ~x"./@Thur"s,                   # Extract availability for Thursday.
                     fri: ~x"./@Fri"s,                     # Extract availability for Friday.
                     sat: ~x"./@Sat"s,                     # Extract availability for Saturday.
                     sun: ~x"./@Sun"s,                     # Extract availability for Sunday.

                     # Extract the BaseByGuestAmts section within each Rate.
                     base_by_guest_amts: [
                       ~x"./ota:BaseByGuestAmts/ota:BaseByGuestAmt"el |> add_namespace("ota", namespaces()["ota"]),
                         amount_before_tax: ~x"./@AmountBeforeTax"s,  # Extract the amount before tax.
                         amount_after_tax: ~x"./@AmountAfterTax"s,    # Extract the amount after tax.
                         number_of_guests: ~x"./@NumberOfGuests"s,    # Extract the number of guests.
                         age_qualifying_code: ~x"./@AgeQualifyingCode"s, # Extract the age qualification code.
                         min_age: ~x"./@MinAge"s,  # Extract the minimum age (optional).
                         max_age: ~x"./@MaxAge"s   # Extract the maximum age (optional).

                     ]
                 ],

                 # Extract the UniqueID section within each RatePlan (unique identifiers for the rate plan).
                 unique_id: [
                   ~x"./ota:UniqueID"o |> add_namespace("ota", namespaces()["ota"]),
                   code: ~x"./@ID"s,   # Extract the unique ID for the rate plan.
                   type: ~x"./@Type"s  # Extract the type of the unique ID (e.g., hotel, rate plan).
                 ]
               ]
             ]
           ]
         ]
       )
  end
end
