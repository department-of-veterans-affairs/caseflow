# frozen_string_literal: true

class Events::CreateClaimantOnEvent
  class << self
    def process!(event:, parser:, decision_review:)
      if parser.claim_review_veteran_is_not_claimant
        # We will create the Person record and add it to the People table if the record does not already exist
        create_person(event, parser) unless Person.find_by(participant_id: parser.claimant_participant_id)
      end
      claimant = Claimant.create!(
        decision_review: decision_review,
        participant_id: parser.claimant_participant_id,
        payee_code: parser.claimant_payee_code,
        type: parser.claimant_type
      )
      claimant
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewCreatedClaimantError, error.message
    end

    def create_person(event, parser)
      person = Person.create(date_of_birth: parser.person_date_of_birth,
                             email_address: parser.person_email_address,
                             first_name: parser.person_first_name,
                             last_name: parser.person_last_name,
                             middle_name: parser.person_middle_name,
                             name_suffix: parser.claimant_name_suffix,
                             ssn: parser.person_ssn,
                             participant_id: parser.claimant_participant_id)

      # We will add the Person record to the EventRecord table to show that the person record was created by the event.
      # We will not add the Claimant record to the EventRecord table because the claimant record has an association with
      # the claim_review (HLR, SC) record and the claim review record has an association with the intake record, which
      # is stored in the EventRecord table.
      EventRecord.create!(event: event, evented_record: person)
    end
  end
end
