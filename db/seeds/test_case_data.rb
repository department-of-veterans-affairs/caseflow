# frozen_string_literal: true

module Seeds
  class TestCaseData < Base
    def initialize
      initial_id_values
    end

    def seed!
      create_limbo_appeals
      create_appeal_no_issues
    end

    private

    def initial_id_values
      @file_number ||= 400_000_000
      @participant_id ||= 800_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1)) ||
            VACOLS::Correspondent.find_by(ssn: format("%<n>09d", n: @file_number + 1))
        @file_number += 2000
        @participant_id += 2000
      end
    end

    def create_veteran(options = {})
      @file_number += 1
      @participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @file_number),
        participant_id: format("%<n>09d", n: @participant_id)
      }
      create(:veteran, params.merge(options))
    end

    def create_limbo_appeals
      5.times do
        create_priority_appeal_no_person
        create_nonpriority_appeal_no_person
        create_appeal_person_null_dob
      end
    end

    # these appeals do not have a person linked to the claimant on the appeal and would be missed
    # due to the inner join of claimants:people while selecting appeals
    def create_priority_appeal_no_person
      appeal = create(:appeal,
                      :direct_review_docket,
                      :ready_for_distribution,
                      :type_cavc_remand,
                      veteran: create_veteran(first_name: "TestAppeal", last_name: "NoPerson"))
      appeal.claimants.first.person.delete
    end

    def create_nonpriority_appeal_no_person
      appeal = create(:appeal,
                      :direct_review_docket,
                      :ready_for_distribution,
                      veteran: create_veteran(first_name: "TestAppeal", last_name: "NoPerson"))
      appeal.claimants.first.person.delete
    end

    # the person linked to these appeals will have a null date_of_birth, only affects nonpriority appeals
    # null date of birth was a case not covered when filtering by date to determine AOD status
    def create_appeal_person_null_dob
      appeal = create(:appeal,
                      :direct_review_docket,
                      :ready_for_distribution,
                      veteran: create_veteran(first_name: "TestAppeal", last_name: "NullDateOfBirth"))
      person = appeal.claimants.first.person
      person.date_of_birth = nil
      person.save!
    end

    def create_appeal_no_issues
      appeal = create(:appeal,
                      :dispatched,
                      issue_count: 0,
                      veteran: create_veteran)
    end
  end
end
