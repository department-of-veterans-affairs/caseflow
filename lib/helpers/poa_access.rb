# frozen_string_literal: true

module WarRoom
  class PoaAccess
    # Legacy Appeals - no POA access when spouse not in people table
    #
    # @param vacols_id [String] VACOLS id for Legacy Appeal
    # @param claimant_participant_id [String] participant ID of spouse
    # @return [true, false] whether the fix was successful
    def initialize(vacols_id, claimant_participant_id)
      @vacols_id = vacols_id
      @claimant_participant_id = claimant_participant_id
      RequestStore[:current_user] = User.system_user
    end

    def run
      # only allow records that are not_found to be remidiated
      unless poa.bgs_record == :not_found
        puts("bgs record exists. Aborting...")
        fail Interrupt
      end

      # due diligence to clean up records that may have been created when looking for an existing record
      poa.destroy!

      # Create person record
      Person.find_or_create_by_participant_id(@claimant_participant_id)

      # Create bgs POA record
      # NOTE: The POA is updated in a before_save callback. It will pull in all data for the created POA
      BgsPowerOfAttorney.find_or_create_by_claimant_participant_id(@claimant_participant_id)

      # Confirm fix by returning the POA for passed in appeal
      appeal.bgs_power_of_attorney.present?
    end

    def legacy_appeal
      return @legacy_appeal if defined?(@legacy_appeal)
      @legacy_appeal = LegacyAppeal.find_by!(vacols_id: @vacols_id)
    end

    def find_or_create_bgs_power_of_attorney!
      # clear memoization on legacy appeals
      appeal.power_of_attorney&.try(:clear_bgs_power_of_attorney!)
      appeal.bgs_power_of_attorney
    end
  end
end
