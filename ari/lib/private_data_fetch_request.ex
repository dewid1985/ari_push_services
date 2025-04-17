defmodule PrivateDataFetchRequest do
  # Import the SweetXml library to parse and query XML using XPath.
  import SweetXml

  # Define a map of namespaces used in the XML structure.
  defp namespaces do
    %{
      "soap" => "http://www.w3.org/2003/05/soap-envelope",  # Namespace for SOAP envelope.
      "oas" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd",  # Namespace for WS-Security.
      "ns"  => "http://www.opentravel.org/OTA/2003/05"     # Namespace for OpenTravel (OTA) data.
    }
  end

  # Public function to parse the incoming XML string.
  #
  # Parameters:
  # - `xml`: A binary string containing the XML data to be parsed.
  #
  # Returns:
  # A map with parsed data including header and body fields.
  def parse(xml) when is_binary(xml) do
    xml
    |> SweetXml.parse(namespace_conformant: true)
    |> xpath(
         ~x"//soap:Envelope" |> add_namespace("soap", namespaces()["soap"]),

         # Extract header section
         header: [
           ~x"//soap:Header" |> add_namespace("soap", namespaces()["soap"]),

           # Extract security credentials (Username and Password).
           security: [
             ~x"//oas:Security" |> add_namespace("oas", namespaces()["oas"]),

             user_name_token: [
               ~x"//oas:UsernameToken" |> add_namespace("oas", namespaces()["oas"]),

               user_name: ~x"//oas:Username/text()"s |> add_namespace("oas", namespaces()["oas"]),
               password: ~x"//oas:Password/text()"s |> add_namespace("oas", namespaces()["oas"])
             ]
           ]
         ],

         # Extract the body section with hotel code, customer code, and pagination.
         body: [
           ~x"//soap:Body" |> add_namespace("soap", namespaces()["soap"]),

           data_fetch: [
             ~x"//ns:DataFetch" |> add_namespace("ns", namespaces()["ns"]),

             # Extract hotel code and customer code attributes.
             hotel_code: ~x"./@HotelCode"s,
             customer_code: ~x"./@CustomerCode"s,

             # Extract pagination information.
             pagination: [
               ~x"./ns:Pagination" |> add_namespace("ns", namespaces()["ns"]),
               offset: ~x"./@Offset"s,
               limit:  ~x"./@Limit"s
             ]
           ]
         ]
       )
  end
end
