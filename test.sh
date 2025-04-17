#!/bin/bash

run_myscript() {
  local index=$1
  local limit=1000
  local offset=$(( index * 1000 ))
  local outfile="output_${offset}.xml"

  curl --location --request POST 'http://localhost:4000/soap/getRates' \
    --header 'Content-Type: text/xml; charset=utf-8' \
    --header 'SOAPAction: Recipient' \
    --data-raw "<soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:oas=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\" xmlns:ns=\"http://www.opentravel.org/OTA/2003/05\">
                 <soap:Header>
                    <oas:Security>
                       <!--Optional:-->
                       <oas:UsernameToken>
                          <!--Optional:-->
                          <oas:Username>test@test.com</oas:Username>
                          <!--Optional:-->
                          <oas:Password>testpassword</oas:Password>
                       </oas:UsernameToken>
                    </oas:Security>
                 </soap:Header>
                 <soap:Body>
                    <ns:DataFetch HotelCode=\"36572\">
                       <ns:Pagination Limit=\"$limit\" Offset=\"$offset\"/>
                    </ns:DataFetch>
                 </soap:Body>
              </soap:Envelope>" -o "$outfile"
}

export -f run_myscript

time parallel -j 10 run_myscript ::: {0..20}