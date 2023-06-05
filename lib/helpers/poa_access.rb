=begin
Legacy Appeals - no POA access when spouse not located in people table
=end

# frozen_string_literal: true

module WarRoom
  module PoaAccess
    def run(file_number:)
      RequestStore[:current_user] = User.system_user

      appeal = Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(file_number)

      # locate poa and verify it returns no record
      # returns an nil record which we will need to delete later
      poa = appeal.power_of_attorney

      unless poa.bgs_record == :not_found
        puts("bgs record was found. Aborting...")
        fail Interrupt
      end

      # 2. Setup - Locate Participant ID.

      # 3. Execute -

      # Clean up
      # clear memoization on legacy appeals
      appeal.power_of_attorney&.try(:clear_bgs_power_of_attorney!)

      poa = appeal.bgs_power_of_attorney

      if poa.blank?
        # noop
      elsif poa.bgs_record == :not_found
        poa.destroy!
      end

      # Create person record
      person = Person.find_or_create_by_participant_id(poa_participant_id)

      # Create bgs POA record
      # NOTE: The POA is updated in a before_save callback. It will pull in all the attrs for the created POA
      BgsPowerOfAttorney.find_or_create_by_claimant_participant_id(poa_participant_id)

      # 4. Confirm fix
      appeal = Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id("some_file_num")
      appeal.bgs_power_of_attorney.present?
    end
  end
end
