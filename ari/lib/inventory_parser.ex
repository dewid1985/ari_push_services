defmodule InventoryParser do
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

           # Extract the WS-Addressing Action element.
           action: ~x"//wsa:Action/text()"s |> add_namespace("wsa", namespaces()["wsa"]),

           # Extract the WS-Addressing ReplyTo element.
           reply_to: [
             ~x"//wsa:ReplyTo" |> add_namespace("wsa", namespaces()["wsa"]),

             # Extract the Address inside the ReplyTo element.
             address: ~x".//wsa:Address/text()"s |> add_namespace("wsa", namespaces()["wsa"])
           ],

           # Extract the WS-Security section.
           security: [
             ~x"//wss:Security" |> add_namespace("wss", namespaces()["wss"]),

             # Extract the UsernameToken from the Security section.
             user_name_token: [
               ~x"//wss:UsernameToken" |> add_namespace("wss", namespaces()["wss"]),

               # Extract the Username and Password from the UsernameToken.
               user_name: ~x"//wss:Username/text()"s |> add_namespace("wss", namespaces()["wss"]),
               password: ~x"//wss:Password/text()"s |> add_namespace("wss", namespaces()["wss"])
             ]
           ],

           # Extract the MessageID and To elements from the header.
           message_id: ~x"//wsa:MessageID/text()"s |> add_namespace("wsa", namespaces()["wsa"]),
           to: ~x"//wsa:To/text()"s |> add_namespace("wsa", namespaces()["wsa"])
         ],

         # Extract and parse the SOAP Body section.
         body: [
           ~x"//soap:Body" |> add_namespace("soap", namespaces()["soap"]),

           # Extract the OTA_HotelInvCountNotifRQ message.
           ota_hotel_inv_count_notif_rq: [
             ~x"//ota:OTA_HotelInvCountNotifRQ" |> add_namespace("ota", namespaces()["ota"]),

             # Extract attributes of the OTA_HotelInvCountNotifRQ message.
             time_stamp: ~x"//@TimeStamp"s,
             version: ~x".//@Version"s,
             message_content_code: ~x"//@MessageContentCode"s,

             # Extract the Inventories section within the message.
             inventories: [
               ~x"./ota:Inventories" |> add_namespace("ota", namespaces()["ota"]),
               hotel_code: ~x"./@HotelCode"s,  # Extract the hotel code.

               # Extract each Inventory element.
               inventory: [
                 ~x"./ota:Inventory"el |> add_namespace("ota", namespaces()["ota"]),
                 status_application_control: [
                   ~x"./ota:StatusApplicationControl" |> add_namespace("ota", namespaces()["ota"]),

                   start: ~x"./@Start"s,
                   end: ~x"./@End"s,
                   inv_type_code: ~x"./@InvTypeCode"s,

                   # Extract the destination system codes.
                   distination_system_codes: [
                     ~x"./ota:DestinationSystemCodes/ota:DestinationSystemCode"el |> add_namespace("ota", namespaces()["ota"]),

                     # Extract the actual code value for each destination system code.
                     text: ~x"./text()"s
                   ]
                 ],
                 inv_counts: [
                   ~x"./ota:InvCounts" |> add_namespace("ota", namespaces()["ota"]),
                   inv_count: [
                     ~x"./ota:InvCount"el |> add_namespace("ota", namespaces()["ota"]),
                     count_type: ~x"./@CountType"s,
                     count: ~x"./@Count"s
                   ]
                 ],
               ],
               # Extract the UniqueID section within each Inventory.
               unique_id: [
                 ~x"./ota:UniqueID"o |> add_namespace("ota", namespaces()["ota"]),
                 code: ~x"./@ID"s,  # Extract the unique ID.
                 type: ~x"./@Type"s  # Extract the type of the unique ID.
               ],
             ]
           ]
         ]
       )
  end
end
