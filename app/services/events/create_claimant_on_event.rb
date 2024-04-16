# frozen_string_literal: true

class Events::CreateClaimantOnEvent
  class << self
    def process!(event:, parser:, decision_review:)
      if parser.claim_review_veteran_is_not_claimant
        create_person(parser) unless Person.find_by(participant_id: parser.claimant_participant_id)

        claimant = Claimant.find_or_create_by!(
          decision_review: decision_review,
          participant_id: parser.claimant_participant_id,
          payee_code: parser.claimant_payee_code
        )
        EventRecord.create!(event: event, backfill_record: claimant)
        claimant
      end
    end

    def create_person(parser)
      Person.create(date_of_birth: parser.person_date_of_birth,
                    email_address: parser.person_email_address,
                    first_name: parser.person_first_name,
                    last_name: parser.person_last_name,
                    middle_name: parser.person_middle_name,
                    name_suffix: parser.claimant_name_suffix,
                    ssn: parser.person_ssn,
                    participant_id: parser.claimant_participant_id)
    end
  end
end
