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

  let!(:hearings_show_rate) do
    disposition_counts = {
      "postponed": 5.0,
      "held": 10.0,
      "no_show": 3.0,
      "cancelled": 2.0
    }
    disposition_counts.each do |disposition, count|
      (1..count).each do
        hearing_day = create(:hearing_day, scheduled_for: end_date - rand(2..15).days)
        create(:hearing, disposition: disposition, hearing_day: hearing_day)
      end
    end
  end

  let!(:non_denial_decisions) do
    number_of_decisions_in_range = 25
    number_of_end_products_created_in_7_days = 10

    bva_dispatcher = create(:user)
    BvaDispatch.singleton.add_user(bva_dispatcher)

    decision_issues = (0...number_of_decisions_in_range).map do
      appeal = create(:appeal, :outcoded, decision_documents: [create(:decision_document)])
      BvaDispatchTask.create_from_root_task(appeal.root_task).update(status: Constants.TASK_STATUSES.completed)
      create(:decision_issue, decision_review: appeal)
    end

    BvaDispatchTask.where(status: Constants.TASK_STATUSES.completed).update_all(closed_at: end_date - 5.days)
    decision_issues.sample(number_of_end_products_created_in_7_days).each do |decision|
      create(
        :end_product_establishment,
        established_at: end_date - 2.days,
        source: decision.decision_review.decision_documents.first
      )
    end
  end

  let!(:reader_adoption_rate) do
    user = create(:user)
    ama_reader_cnt = 12
    legacy_reader_cnt = 4
    legacy_non_reader_cnt = 4

    create_list(:decision_document, ama_reader_cnt, decision_date: end_date - 1.day).each do |doc|
      AppealView.create(appeal: doc.appeal, user: user)
    end

    # FactoryBot.create_list() does not work here because it re-uses the same VACOLS::Case. Use a loop instead.
    legacy_reader_cnt.times do
      doc = create(
        :decision_document,
        appeal: create(:legacy_appeal, vacols_case: create(:case)),
        decision_date: end_date - 1.day
      )
      AppealView.create(appeal: doc.appeal, user: user)
    end
    legacy_non_reader_cnt.times do
      create(
        :decision_document,
        appeal: create(:legacy_appeal, vacols_case: create(:case)),
        decision_date: end_date - 1.day
      )
    end
  end
end
