# frozen_string_literal: true

# tests are all via ExternalApi::BGSService
class ExternalApi::BgsAddressFinder
  include AddressMapper

  # :nocov:
  def initialize(participant_id:, client: nil)
    @participant_id = participant_id
    @client = client
  end

  def mailing_address
    addresses.find { |addr| addr[:type] == "Mailing" }
  end

  def addresses
    @addresses ||= fetch_addresses
  end

  private

  attr_reader :participant_id

  def fetch_addresses
    DBService.release_db_connections

    response = MetricsService.record("BGS: fetch address by participant_id: #{participant_id}",
                                     service: :bgs,
                                     name: "address.find_by_participant_id") do
      client.address.find_all_by_participant_id(participant_id)
    end

    return [] unless response

    # The very first element of the array might not necessarily be an address
    bgs_addresses = Array.wrap(response).select { |addr| addr.key?(:addrs_one_txt) }
    bgs_addresses
      .sort_by { |addr| addr[:efctv_dt] }
      .map { |addr| get_address_from_bgs_address(addr) }
  end

  def client
    @client ||= ExternalApi::BGSService.new.client
  end
  # :nocov:
end
