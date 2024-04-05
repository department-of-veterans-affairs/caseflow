# frozen_string_literal: true

# Service Class that will be utilized by Events::DecisionReviewCreated to create a new Veteran
# when an Event is received and that specific Veteran does not already exist in Caseflow
class Events::CreateVeteranOnEvent
  class << self
    def handle_veteran_creation_on_event(event:, parser:)
      unless veteran_exist?(parser.veteran_ssn)
        create_backfill_veteran(event, parser)
      else
        # return existing Veteran
        Veteran.find_by(ssn: parser.veteran_ssn)
      end
    end

    def veteran_exist?(veteran_ssn)
      Veteran.where(ssn: veteran_ssn).exists?
    end

    private

    def create_backfill_veteran(event, parser)
      # Create Veteran without calling BGS
      vet = Veteran.create!(
        file_number: parser.veteran_file_number,
        ssn: parser.veteran_ssn,
        first_name: parser.veteran_first_name,
        last_name: parser.veteran_last_name,
        middle_name: parser.veteran_middle_name,
        participant_id: parser.veteran_participant_id,
        bgs_last_synced_at: parser.veteran_bgs_last_synced_at,
        name_suffix: parser.veteran_name_suffix,
        date_of_death: parser.veteran_date_of_death
      )

      # Update the CF cache
      if vet.cached_attributes_updatable?
        vet.update_cached_attributes!
      end
      # create EventRecord indicating this is a backfilled Veteran
      EventRecord.create!(event: event, backfill_record: vet)

      vet
    end
  end
end
