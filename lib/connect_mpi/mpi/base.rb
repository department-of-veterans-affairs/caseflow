# frozen_string_literal: true

require "savon"
require "nokogiri"

module MPI
  class Base
    def initialize(ssl_cert_file:, ssl_cert_key_file:, ssl_ca_cert:,
                   env: nil, application: nil, log: false, logger: nil)
      @env = env
      @application = application
      @ssl_cert_file = ssl_cert_file
      @ssl_cert_key_file = ssl_cert_key_file
      @ssl_ca_cert = ssl_ca_cert
      @log = log
      @logger = logger
    end

    def self.service_name
      raise NoMethodError
    end

    private

    def wsdl
      "https://sqa.services.eauth.va.gov:9303/psim_webservice/stage1a/IdMWebService?WSDL"
    end

    def client
      savon_client_params = {
        wsdl: wsdl,
        ssl_cert_file: @ssl_cert_file,
        ssl_cert_key_file: @ssl_cert_key_file,
        ssl_ca_cert_file: @ssl_ca_cert,
        log: @log,
        namespaces: { "xmlns" => "urn:hl7-org:v3" },
        open_timeout: 10, # in seconds
        read_timeout: 600, # in seconds
        convert_request_keys_to: :lower_camelcase
      }
      savon_client_params[:logger] = @logger if @logger
      @client ||= Savon.client(savon_client_params)
    end

    def build_request_xml(method, query)
      request_xml = Nokogiri::XML::DocumentFragment.parse <<-EOXML
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
<s:Body>
<ps:PRPA_IN201305UV02 xmlns:ps="http://vaww.oed.oit.va.gov" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xsi:schemaLocation="urn:hl7-org:v3 ../../schema/HL7V3/NE2008/multicacheschemas/PRPA_IN201305UV02.xsd" xmlns="urn:hl7-org:v3" ITSVersion="XML_1.0">
  <id root="2.16.840.1.113883.4.349" extension="MCID-124147"/> <!-- unique msg id-->
  <creationTime value="20211026150301" /> <!-- date of request -->
  <versionCode code="4.1"/> <!-- should be this value unless specified otherwise -->
  <interactionId root="2.16.840.1.113883.1.6" extension="PRPA_IN201305UV02" />
  <processingCode code="T" /> <!-- T=test, all non-PROD;  P=PROD -->
  <processingModeCode code="T" />
  <acceptAckCode code="AL" />
  <receiver typeCode="RCV">
    <device classCode="DEV" determinerCode="INSTANCE">
      <id root="1.2.840.114350.1.13.999.234" />
      <telecom value="http://servicelocation/PDQuery" />
    </device>
  </receiver>
  <sender typeCode="SND">
    <device classCode="DEV" determinerCode="INSTANCE">
      <id extension="200CFL" root="1.2.840.114350.1.13.99997.2.7788" />
    </device>
  </sender>
  <controlActProcess classCode="CACT" moodCode="EVN">
    <code code="PRPA_TE201301UV02" codeSystem="2.16.840.1.113883.1.6"/>
    <dataEnterer typeCode="ENT" contextControlCode="AP">
      <assignedPerson classCode="ASSIGNED">
        <id extension="CASEFLOWUSER" root="2.16.840.1.113883.4.349"/>
        <assignedPerson determinerCode="INSTANCE" classCode="PSN">
          <name>
            <given>CASEFLOW</given>
            <family>USER</family>
          </name>
        </assignedPerson>
      </assignedPerson>
    </dataEnterer>
  </controlActProcess>
</ps:PRPA_IN201305UV02>
</s:Body>
</s:Envelope>
EOXML
      request_xml.at_xpath(".//*[name()='controlActProcess']").add_child(query)
      dt = DateTime.now
      request_xml.at_xpath(".//*[name()='id']")["extension"] = "MCID-" + dt.strftime("%Y%m%d%H%M%S%L")
      request_xml.at_xpath(".//*[name()='creationTime']")["value"] = dt.strftime("%Y%m%d%H%M%S")
      request_xml
    end

    def request(method, xml)
      client.call(method, xml: xml.to_xml).hash[:envelope][:body]
    end
  end
end
