# frozen_string_literal: true

shared_context "Metrics Reports", shared_context: :metadata do
  before do
    seven_am_random_date = Time.new(2019, 3, 29, 7, 0, 0).in_time_zone
    Timecop.freeze(seven_am_random_date)
  end

  let(:veteran) { create(:veteran) }

  let!(:hlrs) do
    create(:higher_level_review, veteran_file_number: veteran.file_number)
    create(:higher_level_review,
           establishment_submitted_at: 37.days.ago,
           establishment_last_submitted_at: 37.days.ago,
           veteran_file_number: veteran.file_number)
    create(:higher_level_review,
           establishment_submitted_at: 37.days.ago,
           establishment_processed_at: 6.days.ago,
           veteran_file_number: veteran.file_number)
    create(:higher_level_review,
           establishment_submitted_at: 6.days.ago,
           establishment_canceled_at: 5.days.ago,
           veteran_file_number: veteran.file_number)
    create(:higher_level_review,
           establishment_submitted_at: 37.days.ago,
           establishment_processed_at: 37.days.ago + 1.hour,
           veteran_file_number: veteran.file_number)
    create(:higher_level_review,
           establishment_submitted_at: 37.days.ago,
           establishment_processed_at: 37.days.ago + 4.hours,
           veteran_file_number: veteran.file_number)
    create(:higher_level_review,
           establishment_submitted_at: 237.days.ago,
           establishment_processed_at: 37.days.ago,
           veteran_file_number: veteran.file_number)
  end

  let!(:scs) do
    create(:supplemental_claim, veteran_file_number: veteran.file_number)
    create(:supplemental_claim,
           establishment_submitted_at: 37.days.ago,
           establishment_last_submitted_at: 37.days.ago,
           veteran_file_number: veteran.file_number)
    create(:supplemental_claim,
           establishment_submitted_at: 37.days.ago,
           establishment_processed_at: 6.days.ago,
           veteran_file_number: veteran.file_number)
    create(:supplemental_claim,
           establishment_submitted_at: 6.days.ago,
           establishment_processed_at: 5.days.ago,
           veteran_file_number: veteran.file_number)
    create(:supplemental_claim,
           establishment_submitted_at: 37.days.ago,
           establishment_canceled_at: 37.days.ago + 1.hour,
           veteran_file_number: veteran.file_number)
    create(:supplemental_claim,
           establishment_submitted_at: 37.days.ago,
           establishment_processed_at: 37.days.ago + 4.hours,
           veteran_file_number: veteran.file_number)
    create(:supplemental_claim,
           establishment_submitted_at: 237.days.ago,
           establishment_processed_at: 37.days.ago + 4.hours,
           veteran_file_number: veteran.file_number)
  end

  let!(:rius) do
    create(:request_issues_update)
    create(:request_issues_update,
           submitted_at: 37.days.ago,
           processed_at: 5.days.ago)
    create(:request_issues_update,
           submitted_at: 6.days.ago,
           processed_at: 5.days.ago)
    create(:request_issues_update,
           submitted_at: 37.days.ago,
           processed_at: 37.days.ago + 1.hour)
    create(:request_issues_update,
           submitted_at: 37.days.ago,
           canceled_at: 37.days.ago + 4.hours)
  end

  let!(:appeals) do
    create(:appeal, established_at: 35.days.ago)
    create(:appeal, established_at: Time.zone.today)
  end
end
