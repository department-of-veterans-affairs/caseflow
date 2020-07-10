# frozen_string_literal: true

class DuplicateVeteranParticipantIDFinder
  BGS_SSN_FIELD_NAMES = [
    :ssn,
    :soc_sec_number,
    :ssn_nbr
  ].freeze

  def initialize(veteran:)
    @bgs_record = veteran.bgs_record
    @participant_id = veteran.participant_id
    @ssn = veteran.ssn
  end

  # find and return duplicate participant IDs
  def call
    ssns = ([ssn] + BGS_SSN_FIELD_NAMES.map { |field_name| bgs_record[field_name] }).compact.uniq
    ([participant_id] + ssns.map { |ssn| BGSService.new.fetch_person_by_ssn(ssn)&.[](:ptcpnt_id) })
      .compact
      .uniq
  end

  private

  attr_reader :ssn, :participant_id, :bgs_record
end
