defmodule AvailabilityParser do
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
  It processes the XML document using SweetXml with the defined namespaces and extracts relevant data.
  """
  def parse(xml) when is_binary(xml) do
    # Parse the XML string with SweetXml, ensuring namespace conformance.
    xml
    |> SweetXml.parse(namespace_conformant: true)
      # Define the xpath query structure for extracting data from the XML.
      # The `~x` macro is used to define the xpath queries.
    |> xpath(
         ~x"//soap:Envelope" |> add_namespace("soap", namespaces()["soap"]), # Select the SOAP envelope element.
         header: [
           # Extract the SOAP header element and its contents.
           ~x"//soap:Header" |> add_namespace("soap", namespaces()["soap"]),

           # Extract the WS-Addressing action element.
           action: ~x"//wsa:Action/text()"s |> add_namespace("wsa", namespaces()["wsa"]),

           # Extract the WS-Addressing reply-to element.
           reply_to: [
             ~x"//wsa:ReplyTo" |> add_namespace("wsa", namespaces()["wsa"]),

             # Extract the address from the reply-to element.
             address: ~x".//wsa:Address/text()"s |> add_namespace("wsa", namespaces()["wsa"])
           ],

           # Extract WS-Security information from the header.
           security: [
             ~x"//wss:Security" |> add_namespace("wss", namespaces()["wss"]),

             # Extract the UsernameToken element from the security header.
             user_name_token: [
               ~x"//wss:UsernameToken" |> add_namespace("wss", namespaces()["wss"]),

               # Extract the username and password from the UsernameToken.
               user_name: ~x"//wss:Username/text()"s |> add_namespace("wss", namespaces()["wss"]),
               password: ~x"//wss:Password/text()"s |> add_namespace("wss", namespaces()["wss"])
             ]
           ],

           # Extract the message ID and recipient ("to") information from the header.
           message_id: ~x"//wsa:MessageID/text()"s |> add_namespace("wsa", namespaces()["wsa"]),
           to: ~x"//wsa:To/text()"s |> add_namespace("wsa", namespaces()["wsa"])
         ],

         # Extract the SOAP body and its contents.
         body: [
           ~x"//soap:Body" |> add_namespace("soap", namespaces()["soap"]),

           # Extract the OTA_HotelAvailNotifRQ element from the body.
           ota_hotel_avail_notif_rq: [
             ~x"//ota:OTA_HotelAvailNotifRQ" |> add_namespace("ota", namespaces()["ota"]),

             # Extract attributes such as timestamp, version, and message content code.
             time_stamp: ~x"//@TimeStamp"s,
             version: ~x".//@Version"s,
             message_content_code: ~x"//@MessageContentCode"s,

             # Extract availability status messages.
             avail_status_messages: [
               ~x"./ota:AvailStatusMessages" |> add_namespace("ota", namespaces()["ota"]),

               # Extract the hotel code attribute from the availability status messages.
               hotel_code: ~x"./@HotelCode"s,

               # Extract the list of availability status message elements.
               avail_status_message: [
                 ~x"./ota:AvailStatusMessage"el |> add_namespace("ota", namespaces()["ota"]),

                 # Extract the status application control information.
                 status_application_control: [
                   ~x"./ota:StatusApplicationControl" |> add_namespace("ota", namespaces()["ota"]),

                   # Extract the start and end dates, inventory type code, and rate plan code.
                   start: ~x"./@Start"s,
                   end: ~x"./@End"s,
                   inv_type_code: ~x"./@InvTypeCode"s,
                   rate_plan_code: ~x"./@RatePlanCode"s,

                   # Extract day-of-week restrictions (e.g., Sunday to Saturday).
                   sun: ~x"./@Sun"s,
                   mon: ~x"./@Mon"s,
                   tue: ~x"./@Tue"s,
                   weds: ~x"./@Weds"s,
                   thur: ~x"./@Thur"s,
                   fri: ~x"./@Fri"s,
                   sat: ~x"./@Sat"s,

                   # Extract the destination system codes.
                   destination_system_codes: [
                     ~x"./ota:DestinationSystemCodes/ota:DestinationSystemCode"el |> add_namespace("ota", namespaces()["ota"]),

                     # Extract the actual code value for each destination system code.
                     text: ~x"./text()"s
                   ]
                 ],

                 # Extract unique ID information.
                 unique_id: [
                   ~x"./ota:UniqueID"o |> add_namespace("ota", namespaces()["ota"]),

                   # Extract the unique ID and type attributes.
                   code: ~x"./@ID"s,
                   type: ~x"./@Type"s
                 ],

                 # Extract restriction status information.
                 restriction_status: [
                   ~x"./ota:RestrictionStatus"o |> add_namespace("ota", namespaces()["ota"]),

                   # Extract restriction type, status, and booking offsets.
                   restriction: ~x"./@Restriction"s,
                   status: ~x"./@Status"s,
                   max_advanced_booking_offset: ~x"./@MaxAdvancedBookingOffset"s,
                   min_advanced_booking_offset: ~x"./@MinAdvancedBookingOffset"s
                 ],

                 # Extract lengths of stay information.
                 lengths_of_stay: [
                   ~x"./ota:LengthsOfStay"o |> add_namespace("ota", namespaces()["ota"]),

                   # Extract fixed pattern length attribute.
                   fixed_pattern_length: ~x"./@FixedPatternLength"s,

                   # Extract individual length of stay details.
                   length_of_stay: [
                     ~x"./ota:LengthOfStay"l |> add_namespace("ota", namespaces()["ota"]),

                     # Extract the min/max message type, time unit, and time attributes.
                     min_max_message_type: ~x"./@MinMaxMessageType"s,
                     time_unit: ~x"./@TimeUnit"s,
                     time: ~x"./@Time"s
                   ]
                 ]
               ]
             ]
           ]
         ]
       )
  end
end
