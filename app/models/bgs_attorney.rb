# frozen_string_literal: true

# This is for caching (POA) attorney records from BGS for use in adding claimants
# who might not already be associated with a record (hence the use of a different model/table)

class BgsAttorney < CaseflowRecord
  include BgsService

  delegate :address,
           :address_line_1,
           :address_line_2,
           :address_line_3,
           :city,
           :country,
           :state,
           :zip,
           to: :bgs_address_service

  class BgsAttorneyNotFound < StandardError; end

  class << self
    def sync_bgs_attorneys
      now = Time.zone.now
      bgs.poas_list.each do |hash|
        atty = find_or_initialize_by(participant_id: hash[:ptcpnt_id])
        atty.update!(name: hash[:nm], record_type: hash[:org_type_nm], last_synced_at: now)
      end
    end
  end

  def warm_address_cache
    BgsAddressService.new(participant_id: participant_id).refresh_cached_bgs_record
  end

  private

  def bgs_address_service
    @bgs_address_service ||= BgsAddressService.new(participant_id: participant_id)
  end
end
