# frozen_string_literal: true

# When POA is not accessible some users see an error on frontend.
# Others will see a blank POA and when refreshed the POA will still show empty
# The root cause is no person record and we solve this by grabbing
# a new person record and creating the BGS POA if needed.
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
      # clean up any records we don't need
      poa = legacy_appeal.bgs_power_of_attorney

      if poa.bgs_record == :not_found || poa.claimant_participant_id != @claimant_participant_id
        poa.destroy!
      end

      # Create person record
      Person.find_or_create_by_participant_id(@claimant_participant_id)

      # Create bgs POA record
      # NOTE: The POA is updated in a before_save callback. It will pull in all data for the created POA
      BgsPowerOfAttorney.find_or_create_by_claimant_participant_id(@claimant_participant_id)

      # Confirm fix by returning the POA by comparing the claimant_participant_id with the new bgs poa claimant_participant_id
      legacy_appeal.bgs_power_of_attorney.claimant_participant_id == @claimant_participant_id
    end

    def legacy_appeal
      LegacyAppeal.find_by!(vacols_id: @vacols_id)
    end
  end
end
