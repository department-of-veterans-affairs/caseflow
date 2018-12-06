FactoryBot.define do
  factory :appeal do
    transient do
      number_of_claimants nil
    end

    sequence(:veteran_file_number, 500_000_000)

    transient do
      veteran do
        Veteran.find_by(file_number: veteran_file_number) || create(:veteran, file_number: veteran_file_number)
      end
    end

    uuid do
      SecureRandom.uuid
    end

    established_at { Time.zone.now }
    receipt_date { Time.zone.yesterday }

    after(:create) do |appeal, _evaluator|
      appeal.request_issues.each do |issue|
        issue.review_request = appeal
        issue.save
      end
    end

    trait :advanced_on_docket_due_to_age do
      claimants { [create(:claimant, :advanced_on_docket_due_to_age)] }
    end

    trait :advanced_on_docket_due_to_motion do
      claimants do
        claimant = create(:claimant) 
        another_claimant = create(:claimant) 
        create(:advance_on_docket_motion, person: claimant.person, granted: true)
        [claimant, another_claimant]
      end
    end    

    transient do
      documents []
    end

    after(:build) do |appeal, evaluator|
      if evaluator.veteran
        appeal.veteran_file_number = evaluator.veteran.file_number
      end

      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[appeal.veteran_file_number] = evaluator.documents
    end

    after(:create) do |appeal, evaluator|
      if !appeal.claimants.empty?
        appeal.claimants.each do |claimant|
          claimant.review_request = appeal
          claimant.save
        end
      elsif evaluator.number_of_claimants
        appeal.claimants = create_list(:claimant, evaluator.number_of_claimants, review_request: appeal)
      else
        appeal.claimants = [create(
          :claimant,
          participant_id: appeal.veteran.participant_id,
          review_request: appeal,
          payee_code: "00"
        )]
      end
    end
  end
end
