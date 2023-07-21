# frozen_string_literal: true

describe BusinessLine do
  include_context :business_line, "VHA", "vha"
  let(:veteran) { create(:veteran) }

  describe ".tasks_url" do
    it { expect(business_line.tasks_url).to eq "/decision_reviews/vha" }
  end

  describe ".included_tabs" do
    it { expect(business_line.included_tabs).to match_array [:incomplete, :in_progress, :completed] }
  end

  shared_examples "task filtration" do
    context "Higher-Level Review tasks" do
      let!(:task_filters) { ["col=decisionReviewType&val=HigherLevelReview"] }

      it "Returning only Higher-Level Review tasks" do
        expect(
          subject.all? do |task|
            task.type == DecisionReviewTask.name && task.appeal_type == HigherLevelReview.name
          end
        ).to eq true
      end
    end

    context "Supplemental Claim tasks" do
      let!(:task_filters) { ["col=decisionReviewType&val=SupplementalClaim"] }

      it "Returning only Supplemental Claim tasks" do
        expect(
          subject.all? do |task|
            task.type == DecisionReviewTask.name && task.appeal_type == SupplementalClaim.name
          end
        ).to eq true
      end
    end

    context "Veteran Record Request tasks" do
      let!(:task_filters) { ["col=decisionReviewType&val=VeteranRecordRequest"] }

      it "Returning only Veteran Record Request tasks" do
        expect(subject.all? { |task| task.type == VeteranRecordRequest.name }).to eq true
      end
    end

    context "Board Grant Effecutation tasks" do
      let!(:task_filters) { ["col=decisionReviewType&val=BoardGrantEffectuationTask"] }

      context "with :board_grant_effectuation_tasks FeatureToggle enabled" do
        before { FeatureToggle.enable!(:board_grant_effectuation_task) }
        after { FeatureToggle.disable!(:board_grant_effectuation_task) }

        it "Returning only Board Grant Effectuation tasks" do
          expect(subject.all? { |task| task.type == BoardGrantEffectuationTask.name }).to eq true
        end
      end

      context "with :board_grant_effectuation_tasks FeatureToggle disabled" do
        before { FeatureToggle.disable!(:board_grant_effectuation_task) }

        it "Attempting to return only Board Grant Effectuation tasks amounts to either only completed tasks
          or any empty result" do
          tasks = subject

          expect(tasks.empty? || tasks.all?(&:completed?)).to eq true
        end
      end
    end

    context "Invalid column name provided" do
      let!(:task_filters) { ["col=somethingVeryWrongColumn&val=VeteranRecordRequest"] }

      it "Filter value is ignored" do
        expect(subject.all? { |task| task.type == VeteranRecordRequest.name }).to eq false
      end
    end

    context "Filtering by multiple columns" do
      let!(:task_filters) { ["col=decisionReviewType&val=HigherLevelReview|SupplementalClaim"] }

      it "Selected task types are included, but none others" do
        tasks = subject

        expect(tasks.all? { |task| task.type == DecisionReviewTask.name }).to eq true
        expect(tasks.map(&:appeal_type).uniq).to match_array [HigherLevelReview.name, SupplementalClaim.name]
      end
    end

    context "Filtering by issue type" do
      let!(:task_filters) { ["col=issueTypesColumn&val=Beneficiary Travel"] }

      it "Select request issue types are included, none others" do
        tasks = subject
        expect(tasks.all? { |task| task.issue_types.include?("Beneficiary Travel") }).to eq true
      end
    end

    context "Filtering by an issue type that includes | in the string" do
      let!(:task_filters) { ["col=issueTypesColumn&val=Caregiver | Other"] }

      it "Select request issue types are included, none others" do
        tasks = subject
        expect(tasks.all? { |task| task.issue_types.include?("Caregiver | Other") }).to eq true
      end
    end

    context "Filtering by type and an issue type" do
      let!(:task_filters) do
        ["col=issueTypesColumn&val=Beneficiary Travel", "col=decisionReviewType&val=HigherLevelReview"]
      end

      it "Select request issue types are included, none others" do
        tasks = subject
        expect(tasks.all? do |task|
          task.issue_types.include?("Beneficiary Travel") &&
          task.type == DecisionReviewTask.name &&
          task.appeal_type == HigherLevelReview.name
        end).to eq true
      end
    end
  end

  describe ".in_progress_tasks" do
    let!(:hlr_tasks_on_active_decision_reviews) do
      create_list(:higher_level_review_vha_task, 5, assigned_to: business_line)
    end

    let!(:sc_tasks_on_active_decision_reviews) do
      create_list(:supplemental_claim_vha_task, 5, assigned_to: business_line)
    end

    let!(:decision_review_tasks_on_inactive_decision_reviews) do
      create_list(:higher_level_review_task, 5, assigned_to: business_line)
    end

    let!(:board_grant_effectuation_tasks) do
      tasks = create_list(:board_grant_effectuation_task, 5, assigned_to: business_line)

      tasks.each do |task|
        create(
          :request_issue,
          :nonrating,
          decision_review: task.appeal,
          benefit_type: business_line.url,
          closed_at: Time.zone.now,
          closed_status: "decided"
        )
      end

      tasks
    end

    let!(:veteran_record_request_on_active_appeals) do
      add_veteran_and_request_issues_to_decision_reviews(
        create_list(:veteran_record_request_task, 5, assigned_to: business_line)
      )
    end

    let!(:veteran_record_request_on_inactive_appeals) do
      create_list(:veteran_record_request_task, 5, assigned_to: business_line)
    end

    subject { business_line.in_progress_tasks(filters: task_filters) }

    include_examples "task filtration"

    context "With the :board_grant_effectuation_task FeatureToggle enabled" do
      let!(:task_filters) { nil }

      before { FeatureToggle.enable!(:board_grant_effectuation_task) }
      after { FeatureToggle.disable!(:board_grant_effectuation_task) }

      it "All tasks associated with active decision reviews and BoardGrantEffectuationTasks are included" do
        expect(subject.size).to eq 20
        expect(subject.map(&:id)).to match_array(
          (veteran_record_request_on_active_appeals +
            board_grant_effectuation_tasks +
            hlr_tasks_on_active_decision_reviews +
            sc_tasks_on_active_decision_reviews
          ).pluck(:id)
        )
      end
    end

    context "With the :board_grant_effectuation_task FeatureToggle disabled" do
      let!(:task_filters) { nil }

      before { FeatureToggle.disable!(:board_grant_effectuation_task) }

      it "All tasks associated with active decision reviews are included, but not BoardGrantEffectuationTasks" do
        expect(subject.size).to eq 15
        expect(subject.map(&:id)).to match_array(
          (veteran_record_request_on_active_appeals +
            hlr_tasks_on_active_decision_reviews +
            sc_tasks_on_active_decision_reviews
          ).pluck(:id)
        )
      end
    end
  end

  describe ".incomplete_tasks" do
    let!(:hlr_tasks_on_active_decision_reviews) do
      tasks = create_list(:higher_level_review_vha_task, 5, assigned_to: business_line)
      tasks.each(&:on_hold!)
      tasks
    end

    let!(:sc_tasks_on_active_decision_reviews) do
      tasks = create_list(:supplemental_claim_vha_task, 5, assigned_to: business_line)
      tasks.each(&:on_hold!)
      tasks
    end

    # TODO: Presumably this is still fine??
    let!(:decision_review_tasks_on_inactive_decision_reviews) do
      tasks = create_list(:higher_level_review_task, 5, assigned_to: business_line)
      tasks.each(&:on_hold!)
      tasks
    end

    subject { business_line.incomplete_tasks(filters: task_filters) }

    include_examples "task filtration"

    context "with no filters" do
      let!(:task_filters) { nil }

      it "All tasks associated with active decision reviews and BoardGrantEffectuationTasks are included" do
        expect(subject.size).to eq 10
        expect(subject.map(&:id)).to match_array(
          (hlr_tasks_on_active_decision_reviews +
            sc_tasks_on_active_decision_reviews
          ).pluck(:id)
        )
      end
    end
  end

  describe ".completed_tasks" do
    let!(:open_hlr_tasks) do
      add_veteran_and_request_issues_to_decision_reviews(
        create_list(:higher_level_review_task, 5, assigned_to: business_line)
      )
    end

    let!(:completed_hlr_tasks) do
      add_veteran_and_request_issues_to_decision_reviews(
        complete_all_tasks(
          create_list(:higher_level_review_task, 5, assigned_to: business_line)
        )
      )
    end

    let!(:open_sc_tasks) do
      add_veteran_and_request_issues_to_decision_reviews(
        create_list(:supplemental_claim_task, 5, assigned_to: business_line)
      )
    end

    let!(:completed_sc_tasks) do
      add_veteran_and_request_issues_to_decision_reviews(
        complete_all_tasks(
          create_list(:supplemental_claim_task, 5, assigned_to: business_line)
        )
      )
    end

    let!(:open_board_grant_effectuation_tasks) do
      add_veteran_and_request_issues_to_decision_reviews(
        create_list(:board_grant_effectuation_task, 5, assigned_to: business_line)
      )
    end

    let!(:completed_board_grant_effectuation_tasks) do
      add_veteran_and_request_issues_to_decision_reviews(
        complete_all_tasks(
          create_list(:board_grant_effectuation_task, 5, assigned_to: business_line)
        )
      )
    end

    let!(:open_veteran_record_requests) do
      add_veteran_and_request_issues_to_decision_reviews(
        create_list(:veteran_record_request_task, 5, assigned_to: business_line)
      )
    end

    let!(:completed_veteran_record_requests) do
      add_veteran_and_request_issues_to_decision_reviews(
        complete_all_tasks(
          create_list(:veteran_record_request_task, 5, assigned_to: business_line)
        )
      )
    end

    subject { business_line.completed_tasks(filters: task_filters) }

    include_examples "task filtration"

    context "With an empty task filter" do
      let!(:task_filters) { nil }

      it "All completed tasks are included in results" do
        expect(subject.size).to eq 20
        expect(subject.map(&:id)).to match_array(
          (completed_hlr_tasks +
            completed_sc_tasks +
            completed_board_grant_effectuation_tasks +
            completed_veteran_record_requests
          ).pluck(:id)
        )
      end
    end
  end

  describe "Generic Non Comp Org Businessline" do
    include_context :business_line, "NONCOMPORG", "nco"

    describe ".tasks_url" do
      it { expect(business_line.tasks_url).to eq "/decision_reviews/nco" }
    end

    describe ".included_tabs" do
      it { expect(business_line.included_tabs).to match_array [:in_progress, :completed] }
    end

    describe ".in_progress_tasks" do
      let(:current_time) { Time.zone.now }
      let!(:hlr_tasks_on_active_decision_reviews) do
        create_list(:higher_level_review_vha_task, 5, assigned_to: business_line)
      end

      let!(:sc_tasks_on_active_decision_reviews) do
        create_list(:supplemental_claim_vha_task, 5, assigned_to: business_line)
      end

      # Set some on hold tasks as well
      let!(:on_hold_sc_tasks_on_active_decision_reviews) do
        tasks = create_list(:supplemental_claim_vha_task, 5, assigned_to: business_line)
        tasks.each(&:on_hold!)
        tasks
      end

      let!(:decision_review_tasks_on_inactive_decision_reviews) do
        create_list(:higher_level_review_task, 5, assigned_to: business_line)
      end

      let!(:board_grant_effectuation_tasks) do
        tasks = create_list(:board_grant_effectuation_task, 5, assigned_to: business_line)

        tasks.each do |task|
          create(
            :request_issue,
            :nonrating,
            decision_review: task.appeal,
            benefit_type: business_line.url,
            closed_at: current_time,
            closed_status: "decided"
          )
        end

        tasks
      end

      let!(:veteran_record_request_on_active_appeals) do
        add_veteran_and_request_issues_to_decision_reviews(
          create_list(:veteran_record_request_task, 5, assigned_to: business_line)
        )
      end

      let!(:veteran_record_request_on_inactive_appeals) do
        create_list(:veteran_record_request_task, 5, assigned_to: business_line)
      end

      subject { business_line.in_progress_tasks(filters: task_filters) }

      include_examples "task filtration"

      context "With the :board_grant_effectuation_task FeatureToggle enabled" do
        let!(:task_filters) { nil }

        before { FeatureToggle.enable!(:board_grant_effectuation_task) }
        after { FeatureToggle.disable!(:board_grant_effectuation_task) }

        it "All tasks associated with active decision reviews and BoardGrantEffectuationTasks are included" do
          expect(subject.size).to eq 25
          expect(subject.map(&:id)).to match_array(
            (veteran_record_request_on_active_appeals +
              board_grant_effectuation_tasks +
              hlr_tasks_on_active_decision_reviews +
              sc_tasks_on_active_decision_reviews +
              on_hold_sc_tasks_on_active_decision_reviews
            ).pluck(:id)
          )
        end
      end

      context "With the :board_grant_effectuation_task FeatureToggle disabled" do
        let!(:task_filters) { nil }

        before { FeatureToggle.disable!(:board_grant_effectuation_task) }

        it "All tasks associated with active decision reviews are included, but not BoardGrantEffectuationTasks" do
          expect(subject.size).to eq 20
          expect(subject.map(&:id)).to match_array(
            (veteran_record_request_on_active_appeals +
              hlr_tasks_on_active_decision_reviews +
              sc_tasks_on_active_decision_reviews +
              on_hold_sc_tasks_on_active_decision_reviews
            ).pluck(:id)
          )
        end
      end
    end
  end

  def add_veteran_and_request_issues_to_decision_reviews(tasks)
    tasks.each do |task|
      task.appeal.update!(veteran_file_number: veteran.file_number)
      rand(1..4).times do
        create(:request_issue, :nonrating,
               nonrating_issue_category: Constants.ISSUE_CATEGORIES.vha.sample,
               decision_review: task.appeal, benefit_type: business_line.url)
      end
    end

    tasks
  end

  def complete_all_tasks(tasks)
    tasks.each(&:completed!)

    tasks
  end
end
