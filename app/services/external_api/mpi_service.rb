# frozen_string_literal: true

# require "mpi". Once mpi gem file is setup and bundled, need to require gem here
require "nokogiri"

class ExternalApi::MPIService

  # attr_reader :client

  def initialize(client: init_client)
    @client = client

    # These instance variables are used for caching their
    # respective requests
    @people = {}
    @person_info = {}
  end

# preprod = https://preprod.services.eauth.va.gov:9303/psim_webservice/preprod/IdMWebService?WSDL
# prod = https://services.eauth.va.gov:9303/psim_webservice/IdMWebService?WSDL
# https://int.services.eauth.va.gov:9303/psim_webservice/dev/IdMWebService?WSDL
# 
# Inside this block, you can access all methods from your own class, but local variables won’t work.
  client = Savon::Client.new do
    wsdl.document = "https://preprod.services.eauth.va.gov:9303/psim_webservice/preprod/IdMWebService?WSDL"
  end


  def search_people_info(last_name:, first_name: nil, middle_name: nil, date_of_birth: nil, gender: nil, address: nil)
    DBService.release_db_connections

    mpi_info = MetricsService.record("MPI: search people info: \
                            last_name = #{last_name}, \
                            first_name = #{first_name}, \
                            middle_name = #{middle_name}, \
                            date_of_birth = #{date_of_birth}, \
                            gender = #{gender}, \
                            address = #{address}",
                            service: :mpi,
                            name: "people.search_people_info") do
        client.people.search_people_info(
          last_name: last_name,
          first_name: first_name,
          middle_name: middle_name,
          date_of_birth: date_of_birth,
          gender: gender,
          address: address
        )
    end
    return {} unless mpi_info
  end

  def fetch_person_info(icn)
    DBService.release_db_connections

    mpi_info = MetricsService.record("MPI: fetch person info: #{icn}",
                                     service: :mpi,
                                     name: "people.fetch_person_info") do
        client.people.fetch_person_info(icn)
    end

    return {} unless mpi_info

    # Need to verify format of return
    # @person_info[icn] ||= {
    #   first_name: mpi_info[:first_name],
    #   last_name: mpi_info[:last_name],
    #   middle_name: mpi_info[:middle_name],
    # }
  end

  private

  def init_client
    MPI::Services.new(
      ssl_cert_key_file: ENV["BGS_KEY_LOCATION"],
      ssl_cert_file: ENV["BGS_CERT_LOCATION"],
      ssl_ca_cert: ENV["BGS_CA_CERT_LOCATION"],
      log: true,
      logger: Rails.logger
    )
  end
end

# set wsdl, namespaces, open_timeout, and read_timeout in mpi repo



# xml_doc  = Nokogiri::XML("<root><aliens><alien><name>Alf</name></alien></aliens></root>")
# Nokogiri::XML::Document.parse(xml_doc) 

  # version_code: "4.1" - key highlighted MPI 1305 request value doc - versionCode included in request, should be set to "4.1" unless specificied otherwise. Could live in MPI repo. BOTH requests
  # processing_code: "T" = test, all non-Prod. "P" = prod - key highlighted MPI 1305 request value doc  - processingCode included in request. Could live here in Caseflow service file. BOTH requests
  # sender_code: "200CFL" - Sender Code, provided on 10/19 MPI call. BOTH requests
  # log: true - Enable Savon logging
  # modify_code: key highlighted MPI 1305 request value doc - signifies want GetCorrIds in response, only if applicable for 1305 search
  # data_enterer: key highlighted MPI 1305 request value doc. BOTH Requests. Acceptable values for the Data Enterer are as follows: 
    # •	Given and Family equal first and last name of user initiating the request. -OR-
    # •	Given is network ID of user initiating request, Family is system name of application. -OR-
    # •	Family is name of system account. -OR-
    # •	Family is network ID of user initiating request.

  # internal_msg_id: key highlighted MPI 1305 request value doc
  # message_id - key highlighted MPI 1305 request value doc. BOTH requests
  # creation_time - key highlighted MPI 1305 request value doc. BOTH requests

  

  # search traits - Person info. Search Person Attended
  # parameter list - ICN. Retrieve person 


# All 3
# - unique message id: MCID-*****
# - creationTime
# - versionCode
# - processingCode
# - dataEnterer - given="CASEFLOW" family="USER"
# - modifyCode - "MVI.COMP1"


# - Not included in all 3 - internalMessageId and senderCode






sender_code: "200CFL",
version_code: "4.1",
processing_code: "T",
data_enterer: { GIVEN: "CASEFLOW", FAMIlY: "USER"},
modify_code: "MVI.COMP1"
