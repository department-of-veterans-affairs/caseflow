# frozen_string_literal: true

describe BusinessLine do
  include_context :business_line, "VHA", "vha"
  let(:veteran) { create(:veteran) }

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

    context "Remand tasks" do
      let!(:task_filters) { ["col=decisionReviewType&val=Remand"] }

      it "Returning only Remand tasks" do
        expect(
          subject.all? do |task|
            task.type == DecisionReviewTask.name && task.appeal.type == Remand.name
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

    let!(:remand_tasks_on_active_decision_reviews) do
      create_list(:remand_vha_task, 5, assigned_to: business_line)
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
        expect(subject.size).to eq 25
        expect(subject.map(&:id)).to match_array(
          (veteran_record_request_on_active_appeals +
            board_grant_effectuation_tasks +
            hlr_tasks_on_active_decision_reviews +
            sc_tasks_on_active_decision_reviews +
            remand_tasks_on_active_decision_reviews
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
            remand_tasks_on_active_decision_reviews
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

    let!(:completed_remand_tasks) do
      add_veteran_and_request_issues_to_decision_reviews(
        complete_all_tasks(
          create_list(:remand_task, 5, assigned_to: business_line)
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
        expect(subject.size).to eq 25
        expect(subject.map(&:id)).to match_array(
          (completed_hlr_tasks +
            completed_sc_tasks +
            completed_board_grant_effectuation_tasks +
            completed_veteran_record_requests +
            completed_remand_tasks
          ).pluck(:id)
        )
      end
    end
  end

  describe ".pending_tasks" do
    let!(:requestor) { create(:user) }
    let!(:decider) { create(:user) }
    let!(:hlr_pending_tasks) do
      create_list(:issue_modification_request,
                  3,
                  :with_higher_level_review,
                  status: "assigned",
                  requestor: requestor,
                  decider: decider)
    end

    let!(:sc_pending_tasks) do
      create_list(:issue_modification_request,
                  3,
                  :with_supplemental_claim,
                  status: "assigned",
                  requestor: requestor,
                  decider: decider)
    end

    let!(:extra_modification_request) do
      create(:issue_modification_request,
             :with_higher_level_review,
             status: "assigned",
             requestor: requestor,
             decider: decider)
    end

    let(:extra_decision_review) do
      extra_modification_request.decision_review
    end

    let!(:extra_modification_request2) do
      create(:issue_modification_request,
             status: "assigned",
             requestor: requestor,
             decider: decider,
             decision_review: extra_decision_review)
    end

    subject { business_line.pending_tasks(filters: task_filters) }

    include_examples "task filtration"

    context "With an empty task filter" do
      let(:task_filters) { nil }

      it "All pending tasks are included in the results" do
        expect(subject.size).to eq(7)

        expect(subject.map(&:appeal_id)).to match_array(
          (hlr_pending_tasks + sc_pending_tasks + [extra_modification_request]).pluck(:decision_review_id)
        )

        # Verify the issue count and issue modfication count is correct for the extra task
        extra_task = subject.find do |task|
          task.appeal_id == extra_modification_request.decision_review_id &&
            task.appeal_type == "HigherLevelReview"
        end
        expect(extra_task[:issue_count]).to eq(1)
        expect(extra_task[:pending_issue_count]).to eq(2)
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

      let!(:remand_tasks_on_active_decision_reviews) do
        create_list(:remand_vha_task, 5, assigned_to: business_line)
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
          expect(subject.size).to eq 30
          expect(subject.map(&:id)).to match_array(
            (veteran_record_request_on_active_appeals +
              board_grant_effectuation_tasks +
              hlr_tasks_on_active_decision_reviews +
              sc_tasks_on_active_decision_reviews +
              on_hold_sc_tasks_on_active_decision_reviews +
              remand_tasks_on_active_decision_reviews
            ).pluck(:id)
          )
        end
      end

      context "With the :board_grant_effectuation_task FeatureToggle disabled" do
        let!(:task_filters) { nil }

        before { FeatureToggle.disable!(:board_grant_effectuation_task) }

        it "All tasks associated with active decision reviews are included, but not BoardGrantEffectuationTasks" do
          expect(subject.size).to eq 25
          expect(subject.map(&:id)).to match_array(
            (veteran_record_request_on_active_appeals +
              hlr_tasks_on_active_decision_reviews +
              sc_tasks_on_active_decision_reviews +
              on_hold_sc_tasks_on_active_decision_reviews +
              remand_tasks_on_active_decision_reviews
            ).pluck(:id)
          )
        end
      end
    end
  end

  describe ".change_history_rows" do
    let(:change_history_filters) { {} }
    let!(:hlr_task) { create(:higher_level_review_vha_task_with_decision) }
    let!(:hlr_task2) { create(:higher_level_review_vha_task) }
    let!(:sc_task) do
      create(:supplemental_claim_vha_task,
             appeal: create(:supplemental_claim,
                            :with_vha_issue,
                            :with_intake,
                            benefit_type: "vha",
                            claimant_type: :dependent_claimant))
    end
    let!(:remand_task) do
      create(:remand_vha_task,
             appeal: create(:remand,
                            benefit_type: "vha",
                            claimant_type: :dependent_claimant))
    end

    let(:decision_issue) { create(:decision_issue, disposition: "denied", benefit_type: hlr_task.appeal.benefit_type) }
    let(:intake_user) { create(:user, full_name: "Alexander Dewitt", css_id: "ALEXVHA", station_id: "103") }
    let(:decision_user) { create(:user, full_name: "Gaius Baelsar", css_id: "GAIUSVHA", station_id: "104") }

    # Reusable expectations
    let(:hlr_task_1_ri_1_expectation) do
      a_hash_including(
        "nonrating_issue_category" => "Caregiver | Other",
        "nonrating_issue_description" => "VHA - Caregiver ",
        "task_id" => hlr_task.id,
        "veteran_file_number" => hlr_task.appeal.veteran_file_number,
        "intake_user_name" => hlr_task.appeal.intake.user.full_name,
        "intake_user_css_id" => hlr_task.appeal.intake.user.css_id,
        "intake_user_station_id" => hlr_task.appeal.intake.user.station_id,
        "disposition" => "Granted",
        "decision_user_name" => decision_user.full_name,
        "decision_user_css_id" => decision_user.css_id,
        "decision_user_station_id" => decision_user.station_id,
        "claimant_name" => hlr_task.appeal.claimant.name,
        "task_status" => hlr_task.status,
        "request_issue_benefit_type" => "vha",
        "days_waiting" => 10
      )
    end
    let(:hlr_task_1_ri_2_expectation) do
      a_hash_including(
        "nonrating_issue_category" => "CHAMPVA",
        "nonrating_issue_description" => "This is a CHAMPVA issue",
        "task_id" => hlr_task.id,
        "veteran_file_number" => hlr_task.appeal.veteran_file_number,
        "intake_user_name" => hlr_task.appeal.intake.user.full_name,
        "intake_user_css_id" => hlr_task.appeal.intake.user.css_id,
        "intake_user_station_id" => hlr_task.appeal.intake.user.station_id,
        "disposition" => "denied",
        "decision_user_name" => decision_user.full_name,
        "decision_user_css_id" => decision_user.css_id,
        "decision_user_station_id" => decision_user.station_id,
        "claimant_name" => hlr_task.appeal.claimant.name,
        "task_status" => hlr_task.status,
        "request_issue_benefit_type" => "vha",
        "days_waiting" => 10
      )
    end
    let(:hlr_task_2_ri_1_expectation) do
      a_hash_including(
        "nonrating_issue_category" => "Caregiver | Other",
        "nonrating_issue_description" => "VHA - Caregiver ",
        "task_id" => hlr_task2.id,
        "veteran_file_number" => hlr_task2.appeal.veteran_file_number,
        "intake_user_name" => intake_user.full_name,
        "intake_user_css_id" => intake_user.css_id,
        "intake_user_station_id" => intake_user.station_id,
        "disposition" => nil,
        "decision_user_name" => nil,
        "decision_user_css_id" => nil,
        "decision_user_station_id" => nil,
        "claimant_name" => hlr_task2.appeal.claimant.name,
        "task_status" => hlr_task2.status,
        "request_issue_benefit_type" => "vha",
        "days_waiting" => 5
      )
    end
    let(:hlr_task_2_ri_2_expectation) do
      a_hash_including(
        "nonrating_issue_category" => "Camp Lejune Family Member",
        "nonrating_issue_description" => "This is a Camp Lejune issue",
        "task_id" => hlr_task2.id,
        "veteran_file_number" => hlr_task2.appeal.veteran_file_number,
        "intake_user_name" => intake_user.full_name,
        "intake_user_css_id" => intake_user.css_id,
        "intake_user_station_id" => intake_user.station_id,
        "disposition" => nil,
        "decision_user_name" => nil,
        "decision_user_css_id" => nil,
        "decision_user_station_id" => nil,
        "claimant_name" => hlr_task2.appeal.claimant.name,
        "task_status" => hlr_task2.status,
        "request_issue_benefit_type" => "vha",
        "days_waiting" => 5
      )
    end
    let(:sc_task_1_ri_1_expectation) do
      a_hash_including(
        "nonrating_issue_category" => "Beneficiary Travel",
        "nonrating_issue_description" => "VHA issue description ",
        "task_id" => sc_task.id,
        "veteran_file_number" => sc_task.appeal.veteran_file_number,
        "intake_user_name" => sc_task.appeal.intake.user.full_name,
        "intake_user_css_id" => sc_task.appeal.intake.user.css_id,
        "intake_user_station_id" => sc_task.appeal.intake.user.station_id,
        "disposition" => nil,
        "decision_user_name" => nil,
        "decision_user_css_id" => nil,
        "decision_user_station_id" => nil,
        "claimant_name" => sc_task.appeal.claimant.name,
        "task_status" => sc_task.status,
        "request_issue_benefit_type" => "vha",
        "days_waiting" => (Time.zone.today - Date.parse(sc_task.assigned_at.iso8601)).to_i
      )
    end
    let(:remand_task_1_ri_1_expectation) do
      a_hash_including(
        "nonrating_issue_category" => "Clothing Allowance",
        "nonrating_issue_description" => "This is a Clothing Allowance issue",
        "task_id" => remand_task.id,
        "veteran_file_number" => remand_task.appeal.veteran_file_number,
        "intake_user_name" => nil,
        "intake_user_css_id" => nil,
        "intake_user_station_id" => nil,
        "disposition" => nil,
        "decision_user_name" => nil,
        "decision_user_css_id" => nil,
        "decision_user_station_id" => nil,
        "claimant_name" => remand_task.appeal.claimant.name,
        "task_status" => remand_task.status,
        "request_issue_benefit_type" => "vha",
        "days_waiting" => (Time.zone.today - Date.parse(remand_task.assigned_at.iso8601)).to_i
      )
    end

    let(:all_expectations) do
      [
        hlr_task_1_ri_1_expectation,
        hlr_task_1_ri_2_expectation,
        hlr_task_2_ri_1_expectation,
        hlr_task_2_ri_2_expectation,
        sc_task_1_ri_1_expectation,
        remand_task_1_ri_1_expectation
      ]
    end

    before do
      issue = create(:request_issue,
                     nonrating_issue_category: "CHAMPVA",
                     nonrating_issue_description: "This is a CHAMPVA issue",
                     benefit_type: "vha")
      issue2 = create(:request_issue,
                      nonrating_issue_category: "Camp Lejune Family Member",
                      nonrating_issue_description: "This is a Camp Lejune issue",
                      benefit_type: "vha")
      remand_issue = create(:request_issue,
                            nonrating_issue_category: "Clothing Allowance",
                            nonrating_issue_description: "This is a Clothing Allowance issue",
                            benefit_type: "vha",
                            decision_review: remand_task.appeal)
      hlr_task.appeal.request_issues << issue
      hlr_task2.appeal.request_issues << issue2
      remand_task.appeal.request_issues << remand_issue
      remand_task.save
      remand_task.reload

      # Add a different intake user to the second hlr task for data differences
      second_intake = hlr_task2.appeal.intake
      second_intake.user = intake_user
      second_intake.save

      # Add a couple of dispostions one here and one through the factory, to the first hlr task
      decision_issue.request_issues << issue
      hlr_task.appeal.decision_issues << decision_issue
      hlr_task.appeal.save

      # Set the assigned at for days waiting filtering for hlr_task2
      hlr_task2.assigned_at = 5.days.ago
      hlr_task2.save

      # Set up assigned at for days waiting filtering for hlr_task1
      PaperTrail.request(enabled: false) do
        # This uses the task versions whodunnit field now instead of completed by
        # hlr_task.completed_by = decision_user
        hlr_task.assigned_at = 10.days.ago
        hlr_task.save
      end

      # Set the whodunnnit of the completed version status to the decision user
      version = hlr_task.versions.first
      version.whodunnit = decision_user.id.to_s
      version.save
    end

    subject { business_line.change_history_rows(change_history_filters) }

    context "without filters" do
      it "should return all rows" do
        expect(subject.count).to eq 6
        expect(subject.entries).to include(*all_expectations)
      end
    end

    context "with task_id filter" do
      context "with multiple task ids" do
        let(:change_history_filters) { { task_id: [hlr_task.id, sc_task.id, remand_task.id] } }

        it "should return rows for all matching ids" do
          expect(subject.entries.count).to eq(4)
          expect(subject.entries).to include(
            hlr_task_1_ri_1_expectation,
            hlr_task_1_ri_2_expectation,
            sc_task_1_ri_1_expectation,
            remand_task_1_ri_1_expectation
          )
        end
      end

      let(:change_history_filters) { { task_id: hlr_task.id } }

      it "should only return rows for that task" do
        expect(subject.entries.count).to eq(2)
        expect(subject.entries).to include(
          hlr_task_1_ri_1_expectation,
          hlr_task_1_ri_2_expectation
        )
      end
    end

    context "with claim_type filter" do
      context "Supplemental Claim filter" do
        let(:change_history_filters) { { claim_type: "SupplementalClaim" } }

        it "should only return rows for the filtered claim type" do
          expect(subject.entries.count).to eq(1)
          expect(subject.entries).to include(sc_task_1_ri_1_expectation)
        end
      end

      context "Higher-Level Review claim filter" do
        let(:change_history_filters) { { claim_type: "HigherLevelReview" } }

        it "should only return rows for the filtered claim type" do
          expect(subject.entries.count).to eq(4)
          expect(subject.entries).to include(
            *(all_expectations - [sc_task_1_ri_1_expectation] - [remand_task_1_ri_1_expectation])
          )
        end
      end

      context "Remand claim filter" do
        let(:change_history_filters) { { claim_type: ["Remand"] } }

        it "should only return rows for the filtered claim type" do
          expect(subject.entries.count).to eq(1)
          expect(subject.entries).to include(remand_task_1_ri_1_expectation)
        end
      end
    end

    context "with task_status filter" do
      let(:change_history_filters) { { task_status: ["completed"] } }

      it "should only return rows for the filtered status types" do
        expect(subject.entries.count).to eq(2)
        expect(subject.entries).to include(
          hlr_task_1_ri_1_expectation,
          hlr_task_1_ri_2_expectation
        )
      end
    end

    context "with dispositions filter" do
      context "with multiple disposition filters" do
        let(:change_history_filters) { { dispositions: %w[Granted denied] } }

        it "should only return rows for filtered disposition values" do
          expect(subject.entries.count).to eq(2)
          expect(subject.entries).to include(
            hlr_task_1_ri_1_expectation,
            hlr_task_1_ri_2_expectation
          )
        end
      end

      context "with a single disposition filter" do
        let(:change_history_filters) { { dispositions: ["denied"] } }

        it "should only return rows for filtered disposition values" do
          expect(subject.entries.count).to eq(1)
          expect(subject.entries).to include(hlr_task_1_ri_2_expectation)
        end
      end

      context "when the disposition filter includes Blank" do
        let(:change_history_filters) { { dispositions: ["Blank"] } }

        it "should return rows that do not have a disposition" do
          expect(subject.entries.count).to eq(4)
          expect(subject.entries).to include(
            hlr_task_2_ri_1_expectation,
            hlr_task_2_ri_2_expectation,
            sc_task_1_ri_1_expectation,
            remand_task_1_ri_1_expectation
          )
        end

        context "when it includes Blank and another disposition" do
          let(:change_history_filters) { { dispositions: %w[denied Blank] } }

          it "should return rows that match denied or have no disposition" do
            expect(subject.entries.count).to eq(5)
            expect(subject.entries).to include(
              hlr_task_1_ri_2_expectation,
              hlr_task_2_ri_1_expectation,
              hlr_task_2_ri_2_expectation,
              sc_task_1_ri_1_expectation,
              remand_task_1_ri_1_expectation
            )
          end
        end
      end
    end

    context "with issue types filter" do
      context "with multiple issue type filters" do
        let(:change_history_filters) { { issue_types: ["Beneficiary Travel", "CHAMPVA"] } }

        it "should only return rows for the filtered issue type values" do
          expect(subject.entries.count).to eq(2)
          expect(subject.entries).to include(
            hlr_task_1_ri_2_expectation,
            sc_task_1_ri_1_expectation
          )
        end
      end

      context "with a single issue type filter" do
        let(:change_history_filters) { { issue_types: ["Caregiver | Other"] } }

        it "should only return rows for the filtered issue type values" do
          expect(subject.entries.count).to eq(2)
          expect(subject.entries).to include(
            hlr_task_1_ri_1_expectation,
            hlr_task_2_ri_1_expectation
          )
        end
      end
    end

    context "with days waiting filter" do
      context "< filter" do
        let(:change_history_filters) { { days_waiting: { number_of_days: 6, operator: "<" } } }

        it "should only return rows that are under the filtered days waiting value" do
          expect(subject.entries.count).to eq(2)
          expect(subject.entries).to include(
            hlr_task_2_ri_1_expectation,
            hlr_task_2_ri_2_expectation
          )
        end
      end

      context "> filter" do
        let(:change_history_filters) { { days_waiting: { number_of_days: 11, operator: ">" } } }

        it "should only return rows that are over the filtered days waiting value" do
          expect(subject.entries.count).to eq(2)
          expect(subject.entries).to include(
            sc_task_1_ri_1_expectation,
            remand_task_1_ri_1_expectation
          )
        end
      end

      context "= filter" do
        let(:change_history_filters) { { days_waiting: { number_of_days: 10, operator: "=" } } }

        it "should only return rows that are equal to the filtered days waiting value" do
          expect(subject.entries.count).to eq(2)
          expect(subject.entries).to include(
            hlr_task_1_ri_1_expectation,
            hlr_task_1_ri_2_expectation
          )
        end
      end

      context "between filter" do
        let(:change_history_filters) { { days_waiting: { number_of_days: 4, end_days: 11, operator: "between" } } }

        it "should only return rows that are between the number of days and end of days" do
          expect(subject.entries.count).to eq(4)
          expect(subject.entries).to include(
            *(all_expectations - [sc_task_1_ri_1_expectation] - [remand_task_1_ri_1_expectation])
          )
        end
      end
    end

    context "user station id filter" do
      context "when filtering by a station id that has no tasks" do
        let(:change_history_filters) { { facilities: ["702"] } }

        it "should return no rows" do
          expect(subject.entries.count).to eq(0)
          expect(subject.entries).to eq([])
        end
      end

      context "when filtering by multiple station ids" do
        let(:change_history_filters) { { facilities: %w[103 104] } }

        it "only return rows where either an intake, decisions, or updates user matches the station id" do
          expect(subject.entries.count).to eq(4)
          expect(subject.entries).to include(
            *(all_expectations - [sc_task_1_ri_1_expectation] - [remand_task_1_ri_1_expectation])
          )
        end
      end

      context "when filtering by a single station id" do
        let(:change_history_filters) { { facilities: ["101"] } }

        it "only return rows where either an intake, decisions, or updates user matches the station id" do
          expect(subject.entries.count).to eq(3)
          expect(subject.entries).to include(
            hlr_task_1_ri_1_expectation,
            hlr_task_1_ri_2_expectation,
            sc_task_1_ri_1_expectation
          )
        end
      end
    end

    context "user id filter" do
      context "when filtering by a user css id that has no tasks" do
        let(:change_history_filters) { { personnel: ["NOCSSID"] } }

        it "should return no rows" do
          expect(subject.entries.count).to eq(0)
          expect(subject.entries).to eq([])
        end
      end

      context "when filtering by multiple user css ids" do
        let(:change_history_filters) { { personnel: [intake_user.css_id, decision_user.css_id] } }

        it "only return rows where either an intake, decisions, or updates user matches the  css_ids" do
          expect(subject.entries.count).to eq(4)
          expect(subject.entries).to include(
            *(all_expectations - [sc_task_1_ri_1_expectation] - [remand_task_1_ri_1_expectation])
          )
        end
      end

      context "when filtering by a single css id" do
        let(:change_history_filters) { { personnel: [intake_user.css_id] } }

        it "only return rows where either an intake, decisions, or updates user matches the user css id" do
          expect(subject.entries.count).to eq(2)
          expect(subject.entries).to include(
            hlr_task_2_ri_1_expectation,
            hlr_task_2_ri_2_expectation
          )
        end
      end
    end

    context "when filtering by multiple filters at the same time" do
      context "task_id and issue_type" do
        let(:change_history_filters) { { issue_types: ["Caregiver | Other"], task_id: hlr_task.id } }

        it "should only return rows that match both filters" do
          expect(subject.entries.count).to eq(1)
          expect(subject.entries).to include(hlr_task_1_ri_1_expectation)
        end
      end

      context "multiple issue types and claim type" do
        let(:change_history_filters) do
          { issue_types: ["Beneficiary Travel", "CHAMPVA"], claim_type: "SupplementalClaim" }
        end

        it "should only return rows that match both filters" do
          expect(subject.entries.count).to eq(1)
          expect(subject.entries).to include(sc_task_1_ri_1_expectation)
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
