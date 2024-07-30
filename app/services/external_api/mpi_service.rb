# frozen_string_literal: true

require "mpi"

class ExternalApi::MPIService
  attr_reader :client

  def initialize(client: init_client)
    @client = client

    # These instance variables are used for caching their
    # respective requests
    @people = {}
    @person_info = {}
  end

  # rubocop:disable Metrics/ParameterLists
  # rubocop:disable Metrics/MethodLength
  def search_people_info(last_name:, first_name: nil, middle_name: nil,
                         ssn: nil, date_of_birth: nil, gender: nil, address: nil, telephone: nil)
    DBService.release_db_connections

    mpi_info = MetricsService.record("MPI: search people info: \
                                     last_name = #{last_name}, \
                                     first_name = #{first_name}, \
                                     middle_name = #{middle_name}, \
                                     ssn = #{ssn}, \
                                     date_of_birth = #{date_of_birth}, \
                                     gender = #{gender}, \
                                     address = #{address}, \
                                     telephone = #{telephone}",
                                     service: :mpi,
                                     name: "people.search_people_info") do
      client.people.search_people_info(
        last_name: last_name,
        first_name: first_name,
        middle_name: middle_name,
        ssn: ssn,
        date_of_birth: date_of_birth,
        gender: gender,
        address: address,
        telephone: telephone
      )
    end
    mpi_info || {}
  end
  # rubocop:enable Metrics/ParameterLists
  # rubocop:enable Metrics/MethodLength

  def fetch_person_info(icn)
    DBService.release_db_connections

    mpi_info = MetricsService.record("MPI: fetch person info: #{icn}",
                                     service: :mpi,
                                     name: "people.fetch_person_info") do
      client.people.fetch_person_info(icn)
    end
    mpi_info || {}
    # Dependent on parsing format in MPI Gem. Will need to be updated
    # @person_info[icn] ||= {}
  end

  private

  def init_client
    MPI::Services.new(
      ssl_cert_key_file: ENV["BGS_KEY_LOCATION"],
      ssl_cert_file: ENV["BGS_CERT_LOCATION"],
      ssl_ca_cert: ENV["BGS_CA_CERT_LOCATION"],
      wsdl_url: "#{service_url}?WSDL",
      log: true,
      logger: Rails.logger
    )
  end

  def service_url
    case ENV["DEPLOY_ENV"]
    when "development"
      "https://int.services.eauth.va.gov:9303/psim_webservice/dev/IdMWebService"
    when "uat"
      "https://sqa.services.eauth.va.gov:9303/psim_webservice/stage1a/IdMWebService"
    when "preprod"
      "https://preprod.services.eauth.va.gov:9303/psim_webservice/preprod/IdMWebService"
    when "prod"
      "https://services.eauth.va.gov:9303/psim_webservice/IdMWebService"
    end
  end
end
