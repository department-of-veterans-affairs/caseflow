# frozen_string_literal: true

shared_context "Metrics Reports", shared_context: :metadata do
  before do
    seven_am_random_date = Time.new(2019, 3, 29, 7, 0, 0).in_time_zone
    Timecop.freeze(seven_am_random_date)
  end

  let(:veteran) { create(:veteran) }
  let(:start_date) { 2.months.ago }
  let(:end_date) { 1.month.ago }
  let(:date_range) { Metrics::DateRange.new(start_date, end_date) }

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

  let!(:paperless_cases) do
    10.times do
      vacols_case = create(:case, :certified, :type_original, bf41stat: 37.days.ago)
      vacols_case.folder.update!(tivbms: "Y")
    end
  end

  let!(:paper_cases) do
    5.times do
      vacols_case = create(:case, :certified, :type_original, bf41stat: 37.days.ago)
      vacols_case.folder.update!(tivbms: "N")
    end
  end

  let!(:paperless_not_caseflow_cases) do
    5.times do
      vacols_case = create(:case, :type_original, bf41stat: 37.days.ago)
      vacols_case.folder.update!(tivbms: "Y")
    end
  end

  let!(:paper_not_caseflow_cases) do
    5.times do
      vacols_case = create(:case, :type_original, bf41stat: 37.days.ago)
      vacols_case.folder.update!(tivbms: "N")
    end
  end
end
