# frozen_string_literal: true

# Find all the Appeals/LegacyAppeals for the intersection of a Veteran and Power of Attorney.

class AppealsForPOA
  def initialize(veteran_file_number:, poa_participant_ids:)
    @veteran_file_number = veteran_file_number
    @poa_participant_ids = poa_participant_ids
  end

  def call
    accessible_appeals_for_poa
  end

  private

  attr_reader :veteran_file_number, :poa_participant_ids

  def accessible_appeals_for_poa
    appeals = Appeal.established.where(veteran_file_number: veteran_file_number).includes(:claimants)
    legacy_appeals = LegacyAppeal.fetch_appeals_by_file_number(veteran_file_number)

    poas = poas_for_appeals(appeals, legacy_appeals)

    [
      appeals.select do |appeal|
        appeal.claimants.any? do |claimant|
          poa_participant_ids.include?(poas[claimant[:participant_id]][:participant_id])
        end
      end,
      legacy_appeals.select do |legacy_appeal|
        poa_participant_ids.include?(poas[legacy_appeal.veteran.participant_id][:participant_id])
      end
    ].flatten
  end

  def poas_for_appeals(appeals, legacy_appeals)
    claimants_participant_ids = appeals.map { |appeal| appeal.claimants.pluck(:participant_id) }.flatten
      .concat(legacy_appeals.map { |legacy_appeal| legacy_appeal.veteran.participant_id }.flatten)

    bgs.fetch_poas_by_participant_ids(claimants_participant_ids.uniq)
  end

  def bgs
    @bgs ||= BGSService.new
  end
end
