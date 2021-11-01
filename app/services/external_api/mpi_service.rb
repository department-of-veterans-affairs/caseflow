# frozen_string_literal: true

# require "mpi". Once mpi gem file is setup and bundled, need to require gem here

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
    {} unless mpi_info
  end
  # rubocop:enable Metrics/ParameterLists

  def fetch_person_info(icn)
    DBService.release_db_connections

    mpi_info = MetricsService.record("MPI: fetch person info: #{icn}",
                                     service: :mpi,
                                     name: "people.fetch_person_info") do
      client.people.fetch_person_info(icn)
    end

   {} unless mpi_info

    # Dependent on parsing format in MPI Gem. Will need to be updated
    # @person_info[icn] ||= {}
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
