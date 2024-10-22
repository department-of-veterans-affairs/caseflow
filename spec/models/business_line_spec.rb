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
    before(:all) do
      @business_line = VhaBusinessLine.singleton
      @veteran = create(:veteran)

      @hlr_tasks_on_active_decision_reviews =
        create_list(:higher_level_review_vha_task, 5, assigned_to: @business_line)

      @sc_tasks_on_active_decision_reviews =
        create_list(:supplemental_claim_vha_task, 5, assigned_to: @business_line)

      @decision_review_tasks_on_inactive_decision_reviews =
        create_list(:higher_level_review_task, 5, assigned_to: @business_line)

      @board_grant_effectuation_tasks =
        create_list(:board_grant_effectuation_task, 5, assigned_to: @business_line)

      @remand_tasks_on_active_decision_reviews = create_list(:remand_vha_task, 5, assigned_to: @business_line)

      @board_grant_effectuation_tasks.each do |task|
        create(
          :request_issue,
          :nonrating,
          decision_review: task.appeal,
          benefit_type: @business_line.url,
          closed_at: Time.zone.now,
          closed_status: "decided"
        )
      end

      @veteran_record_request_on_active_appeals = add_veteran_and_request_issues_to_decision_reviews(
        create_list(:veteran_record_request_task, 5, assigned_to: @business_line),
        @veteran,
        @business_line
      )

      @veteran_record_request_on_inactive_appeals =
        create_list(:veteran_record_request_task, 5, assigned_to: @business_line)
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
          (@veteran_record_request_on_active_appeals +
            @board_grant_effectuation_tasks +
            @hlr_tasks_on_active_decision_reviews +
            @sc_tasks_on_active_decision_reviews +
            @remand_tasks_on_active_decision_reviews
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
          (@veteran_record_request_on_active_appeals +
            @hlr_tasks_on_active_decision_reviews +
            @sc_tasks_on_active_decision_reviews +
            @remand_tasks_on_active_decision_reviews
          ).pluck(:id)
        )
      end
    end
  end

  describe ".incomplete_tasks" do
    before(:all) do
      @business_line = VhaBusinessLine.singleton
      @veteran = create(:veteran)

      @hlr_tasks_on_active_decision_reviews =
        create_list(:higher_level_review_vha_task, 5, assigned_to: @business_line).each(&:on_hold!)

      @sc_tasks_on_active_decision_reviews =
        create_list(:supplemental_claim_vha_task, 5, assigned_to: @business_line).each(&:on_hold!)

      @decision_review_tasks_on_inactive_decision_reviews =
        create_list(:higher_level_review_task, 5, assigned_to: @business_line).each(&:on_hold!)
    end

    subject { business_line.incomplete_tasks(filters: task_filters) }

    include_examples "task filtration"

    context "with no filters" do
      let!(:task_filters) { nil }

      it "All tasks associated with active decision reviews and BoardGrantEffectuationTasks are included" do
        expect(subject.size).to eq 10
        expect(subject.map(&:id)).to match_array(
          (@hlr_tasks_on_active_decision_reviews +
            @sc_tasks_on_active_decision_reviews
          ).pluck(:id)
        )
      end
    end
  end

  describe ".completed_tasks" do
    before(:all) do
      @business_line = VhaBusinessLine.singleton
      @veteran = create(:veteran)

      @open_hlr_tasks = add_veteran_and_request_issues_to_decision_reviews(
        create_list(:higher_level_review_task, 5, assigned_to: @business_line),
        @veteran,
        @business_line
      )

      @completed_hlr_tasks = add_veteran_and_request_issues_to_decision_reviews(
        complete_all_tasks(
          create_list(:higher_level_review_task, 5, assigned_to: @business_line)
        ),
        @veteran,
        @business_line
      )

      @open_sc_tasks = add_veteran_and_request_issues_to_decision_reviews(
        create_list(:supplemental_claim_task, 5, assigned_to: @business_line),
        @veteran,
        @business_line
      )

      @completed_remand_tasks = add_veteran_and_request_issues_to_decision_reviews(
        complete_all_tasks(
          create_list(:remand_task, 5, assigned_to: @business_line)
        ),
        @veteran,
        @business_line
      )

      @completed_sc_tasks = add_veteran_and_request_issues_to_decision_reviews(
        complete_all_tasks(
          create_list(:supplemental_claim_task, 5, assigned_to: @business_line)
        ),
        @veteran,
        @business_line
      )

      @open_board_grant_effectuation_tasks = add_veteran_and_request_issues_to_decision_reviews(
        create_list(:board_grant_effectuation_task, 5, assigned_to: @business_line),
        @veteran,
        @business_line
      )

      @completed_board_grant_effectuation_tasks = add_veteran_and_request_issues_to_decision_reviews(
        complete_all_tasks(
          create_list(:board_grant_effectuation_task, 5, assigned_to: @business_line)
        ),
        @veteran,
        @business_line
      )

      @open_veteran_record_request = add_veteran_and_request_issues_to_decision_reviews(
        create_list(:veteran_record_request_task, 5, assigned_to: @business_line),
        @veteran,
        @business_line
      )

      @completed_veteran_record_requests = add_veteran_and_request_issues_to_decision_reviews(
        complete_all_tasks(
          create_list(:veteran_record_request_task, 5, assigned_to: @business_line)
        ),
        @veteran,
        @business_line
      )
    end

    subject { business_line.completed_tasks(filters: task_filters) }

    include_examples "task filtration"

    context "With an empty task filter" do
      let!(:task_filters) { nil }

      it "All completed tasks are included in results" do
        expect(subject.size).to eq 25
        expect(subject.map(&:id)).to match_array(
          (@completed_hlr_tasks +
            @completed_sc_tasks +
            @completed_board_grant_effectuation_tasks +
            @completed_veteran_record_requests +
            @completed_remand_tasks
          ).pluck(:id)
        )
      end
    end

    context "With closed at filters" do
      context "with a before filter" do
        # Create some closed tasks that should match the before filter
        let!(:tasks_for_closed_at_filter) do
          tasks = add_veteran_and_request_issues_to_decision_reviews(
            complete_all_tasks(
              create_list(:supplemental_claim_task, 5, assigned_to: @business_line)
            ),
            @veteran,
            @business_line
          )
          tasks.each do |task|
            task.closed_at = 5.days.ago
            task.save
          end
          tasks
        end

        let(:task_filters) do
          ["col=completedDateColumn&val=before,#{3.days.ago.strftime('%Y-%m-%d')},"]
        end

        it "should filter the tasks for a date before the closed at date" do
          expect(subject.size).to eq 5
          expect(subject.map(&:id)).to match_array(tasks_for_closed_at_filter.pluck(:id))
        end
      end

      context "with an after filter" do
        # Create some closed tasks that should not match the after filter
        let!(:tasks_for_closed_at_filter) do
          tasks = add_veteran_and_request_issues_to_decision_reviews(
            complete_all_tasks(
              create_list(:supplemental_claim_task, 5, assigned_to: @business_line)
            ),
            @veteran,
            @business_line
          )
          tasks.each do |task|
            task.closed_at = 5.days.ago
            task.save
          end
          tasks
        end

        let(:task_filters) do
          ["col=completedDateColumn&val=after,#{3.days.ago.strftime('%Y-%m-%d')},"]
        end

        it "should filter the tasks for a date after the closed at date" do
          expect(subject.size).to eq 25
          expect(subject.map(&:id)).to match_array(
            (@completed_hlr_tasks +
             @completed_sc_tasks +
             @completed_board_grant_effectuation_tasks +
             @completed_veteran_record_requests +
             @completed_remand_tasks
            ).pluck(:id)
          )
        end
      end

      context "with a between filter" do
        # Create some closed tasks that should match the between filter
        let!(:tasks_for_closed_at_filter) do
          tasks = add_veteran_and_request_issues_to_decision_reviews(
            complete_all_tasks(
              create_list(:supplemental_claim_task, 3, assigned_to: @business_line)
            ),
            @veteran,
            @business_line
          )
          # Set two tasks to fit into the between range
          tasks[0].closed_at = 5.days.ago
          tasks[1].closed_at = 1.day.ago
          tasks[2].closed_at = 8.days.ago
          tasks[0].save
          tasks[1].save
          tasks[2].save
          tasks
        end

        let(:task_filters) do
          start_date = 3.days.ago.strftime("%Y-%m-%d")
          end_date = 10.days.ago.strftime("%Y-%m-%d")
          ["col=completedDateColumn&val=between,#{start_date},#{end_date}"]
        end

        it "should filter the tasks for a closed at date between two dates" do
          expect(subject.size).to eq 2
          expect(subject.map(&:id)).to match_array(
            [
              tasks_for_closed_at_filter[0].id,
              tasks_for_closed_at_filter[2].id
            ]
          )
        end
      end

      context "with last 7 days filter" do
        # Create some closed tasks that should not match the last 7 days filter
        let!(:tasks_for_closed_at_filter) do
          tasks = add_veteran_and_request_issues_to_decision_reviews(
            complete_all_tasks(
              create_list(:supplemental_claim_task, 3, assigned_to: @business_line)
            ),
            @veteran,
            @business_line
          )
          tasks.each do |task|
            task.closed_at = 10.days.ago
            task.save
          end
          tasks
        end

        let(:task_filters) do
          ["col=completedDateColumn&val=last7,,"]
        end

        it "should filter the tasks for a closed at in the last 7 days" do
          expect(subject.size).to eq 25
          expect(subject.map(&:id)).to match_array(
            (@completed_hlr_tasks +
             @completed_sc_tasks +
             @completed_board_grant_effectuation_tasks +
             @completed_veteran_record_requests +
             @completed_remand_tasks
            ).pluck(:id)
          )
        end
      end

      context "with last 30 days filter" do
        # Create some closed tasks that should match the last 30 days filter and one that does not
        let!(:tasks_for_closed_at_filter) do
          tasks = add_veteran_and_request_issues_to_decision_reviews(
            complete_all_tasks(
              create_list(:supplemental_claim_task, 3, assigned_to: @business_line)
            ),
            @veteran,
            @business_line
          )
          tasks.first(2) do |task|
            task.closed_at = 10.days.ago
            task.save
          end
          tasks.last.closed_at = 31.days.ago
          tasks.last.save
          tasks
        end

        let(:task_filters) do
          ["col=completedDateColumn&val=last30,,"]
        end

        it "should filter the tasks for a closed at in the last 30 days" do
          expect(subject.size).to eq 27
          expect(subject.map(&:id)).to match_array(
            (@completed_hlr_tasks +
             @completed_sc_tasks +
             @completed_board_grant_effectuation_tasks +
             @completed_veteran_record_requests +
             @completed_remand_tasks +
             tasks_for_closed_at_filter.first(2)
            ).pluck(:id)
          )
        end
      end

      context "with last 365 days filter" do
        # Create some closed tasks that should match the last 365 days filter and one that does not
        let!(:tasks_for_closed_at_filter) do
          tasks = add_veteran_and_request_issues_to_decision_reviews(
            complete_all_tasks(
              create_list(:supplemental_claim_task, 3, assigned_to: @business_line)
            ),
            @veteran,
            @business_line
          )
          tasks.first(2) do |task|
            task.closed_at = 200.days.ago
            task.save
          end
          tasks.last.closed_at = 400.days.ago
          tasks.last.save
          tasks
        end

        let(:task_filters) do
          ["col=completedDateColumn&val=last365,,"]
        end

        it "should filter the tasks for a closed at in the last 365 days" do
          expect(subject.size).to eq 27
          expect(subject.map(&:id)).to match_array(
            (@completed_hlr_tasks +
             @completed_sc_tasks +
             @completed_board_grant_effectuation_tasks +
             @completed_veteran_record_requests +
             @completed_remand_tasks +
             tasks_for_closed_at_filter.first(2)
            ).pluck(:id)
          )
        end
      end
    end
  end

  describe ".pending_tasks" do
    before(:all) do
      @requestor = create(:user)
      @decider = create(:user)
      @hlr_pending_tasks = create_list(:issue_modification_request,
                                       3,
                                       :with_higher_level_review,
                                       status: "assigned",
                                       requestor: @requestor,
                                       decider: @decider)

      @sc_pending_tasks = create_list(:issue_modification_request,
                                      3,
                                      :with_supplemental_claim,
                                      status: "assigned",
                                      requestor: @requestor,
                                      decider: @decider)

      @extra_modification_request = create(:issue_modification_request,
                                           :with_higher_level_review,
                                           status: "assigned",
                                           requestor: @requestor,
                                           decider: @decider)

      @extra_decision_review = @extra_modification_request.decision_review

      @extra_modification_request2 = create(:issue_modification_request,
                                            status: "assigned",
                                            requestor: @requestor,
                                            decider: @decider,
                                            decision_review: @extra_decision_review)
    end

    subject { business_line.pending_tasks(filters: task_filters) }

    include_examples "task filtration"

    context "With an empty task filter" do
      let(:task_filters) { nil }

      it "All pending tasks are included in the results" do
        expect(subject.size).to eq(7)

        expect(subject.map(&:appeal_id)).to match_array(
          (@hlr_pending_tasks + @sc_pending_tasks + [@extra_modification_request]).pluck(:decision_review_id)
        )

        # Verify the issue count and issue modfication count is correct for the extra task
        extra_task = subject.find do |task|
          task.appeal_id == @extra_modification_request.decision_review_id &&
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
      before(:all) do
        @current_time = Time.zone.now
        # Use a different url and name since the let variable can't be used in before all setup
        @business_line = create(:business_line, name: "NONCOMPORG2", url: "nco2")

        @veteran = create(:veteran)

        @hlr_tasks_on_active_decision_reviews =
          create_list(:higher_level_review_vha_task, 5, assigned_to: @business_line)

        @remand_tasks_on_active_decision_reviews = create_list(:remand_vha_task, 5, assigned_to: @business_line)

        @sc_tasks_on_active_decision_reviews =
          create_list(:supplemental_claim_vha_task, 5, assigned_to: @business_line)

        @on_hold_sc_tasks_on_active_decision_reviews =
          create_list(:supplemental_claim_vha_task, 5, assigned_to: @business_line).each(&:on_hold!)

        @decision_review_tasks_on_inactive_decision_reviews =
          create_list(:higher_level_review_task, 5, assigned_to: @business_line)

        @board_grant_effectuation_tasks =
          create_list(:board_grant_effectuation_task, 5, assigned_to: @business_line)

        @board_grant_effectuation_tasks.each do |task|
          create(
            :request_issue,
            :nonrating,
            decision_review: task.appeal,
            benefit_type: @business_line.url,
            closed_at: @current_time,
            closed_status: "decided"
          )
        end

        @veteran_record_request_on_active_appeals =
          add_veteran_and_request_issues_to_decision_reviews(
            create_list(:veteran_record_request_task, 5, assigned_to: @business_line),
            @veteran,
            @business_line
          )

        @veteran_record_request_on_inactive_appeals =
          create_list(:veteran_record_request_task, 5, assigned_to: @business_line)
      end

      subject { @business_line.in_progress_tasks(filters: task_filters) }

      include_examples "task filtration"

      context "With the :board_grant_effectuation_task FeatureToggle enabled" do
        let!(:task_filters) { nil }

        before { FeatureToggle.enable!(:board_grant_effectuation_task) }
        after { FeatureToggle.disable!(:board_grant_effectuation_task) }

        it "All tasks associated with active decision reviews and BoardGrantEffectuationTasks are included" do
          expect(subject.size).to eq 30
          expect(subject.map(&:id)).to match_array(
            (@veteran_record_request_on_active_appeals +
              @board_grant_effectuation_tasks +
              @hlr_tasks_on_active_decision_reviews +
              @sc_tasks_on_active_decision_reviews +
              @on_hold_sc_tasks_on_active_decision_reviews +
              @remand_tasks_on_active_decision_reviews
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
            (@veteran_record_request_on_active_appeals +
              @hlr_tasks_on_active_decision_reviews +
              @sc_tasks_on_active_decision_reviews +
              @on_hold_sc_tasks_on_active_decision_reviews +
              @remand_tasks_on_active_decision_reviews
            ).pluck(:id)
          )
        end
      end
    end
  end

  describe ".change_history_rows" do
    let(:change_history_filters) { {} }

    # Reusable expectations
    let(:hlr_task_1_ri_1_expectation) do
      a_hash_including(
        "nonrating_issue_category" => "Caregiver | Other",
        "nonrating_issue_description" => "VHA - Caregiver",
        "task_id" => @hlr_task.id,
        "veteran_file_number" => @hlr_task.appeal.veteran_file_number,
        "intake_user_name" => @hlr_task.appeal.intake.user.full_name,
        "intake_user_css_id" => @hlr_task.appeal.intake.user.css_id,
        "intake_user_station_id" => @hlr_task.appeal.intake.user.station_id,
        "disposition" => "Granted",
        "decision_user_name" => @decision_user.full_name,
        "decision_user_css_id" => @decision_user.css_id,
        "decision_user_station_id" => @decision_user.station_id,
        "claimant_name" => @hlr_task.appeal.claimant.name,
        "task_status" => @hlr_task.status,
        "request_issue_benefit_type" => "vha",
        "days_waiting" => 10
      )
    end
    let(:hlr_task_1_ri_2_expectation) do
      a_hash_including(
        "nonrating_issue_category" => "CHAMPVA",
        "nonrating_issue_description" => "This is a CHAMPVA issue",
        "task_id" => @hlr_task.id,
        "veteran_file_number" => @hlr_task.appeal.veteran_file_number,
        "intake_user_name" => @hlr_task.appeal.intake.user.full_name,
        "intake_user_css_id" => @hlr_task.appeal.intake.user.css_id,
        "intake_user_station_id" => @hlr_task.appeal.intake.user.station_id,
        "disposition" => "denied",
        "decision_user_name" => @decision_user.full_name,
        "decision_user_css_id" => @decision_user.css_id,
        "decision_user_station_id" => @decision_user.station_id,
        "claimant_name" => @hlr_task.appeal.claimant.name,
        "task_status" => @hlr_task.status,
        "request_issue_benefit_type" => "vha",
        "days_waiting" => 10
      )
    end
    let(:hlr_task_2_ri_1_expectation) do
      a_hash_including(
        "nonrating_issue_category" => "Caregiver | Other",
        "nonrating_issue_description" => "VHA - Caregiver",
        "task_id" => @hlr_task2.id,
        "veteran_file_number" => @hlr_task2.appeal.veteran_file_number,
        "intake_user_name" => @intake_user.full_name,
        "intake_user_css_id" => @intake_user.css_id,
        "intake_user_station_id" => @intake_user.station_id,
        "disposition" => nil,
        "decision_user_name" => nil,
        "decision_user_css_id" => nil,
        "decision_user_station_id" => nil,
        "claimant_name" => @hlr_task2.appeal.claimant.name,
        "task_status" => @hlr_task2.status,
        "request_issue_benefit_type" => "vha",
        "days_waiting" => 5
      )
    end
    let(:hlr_task_2_ri_2_expectation) do
      a_hash_including(
        "nonrating_issue_category" => "Camp Lejune Family Member",
        "nonrating_issue_description" => "This is a Camp Lejune issue",
        "task_id" => @hlr_task2.id,
        "veteran_file_number" => @hlr_task2.appeal.veteran_file_number,
        "intake_user_name" => @intake_user.full_name,
        "intake_user_css_id" => @intake_user.css_id,
        "intake_user_station_id" => @intake_user.station_id,
        "disposition" => nil,
        "decision_user_name" => nil,
        "decision_user_css_id" => nil,
        "decision_user_station_id" => nil,
        "claimant_name" => @hlr_task2.appeal.claimant.name,
        "task_status" => @hlr_task2.status,
        "request_issue_benefit_type" => "vha",
        "days_waiting" => 5
      )
    end
    let(:sc_task_1_ri_1_expectation) do
      a_hash_including(
        "nonrating_issue_category" => "Beneficiary Travel",
        "nonrating_issue_description" => "VHA issue description ",
        "task_id" => @sc_task.id,
        "veteran_file_number" => @sc_task.appeal.veteran_file_number,
        "intake_user_name" => @sc_task.appeal.intake.user.full_name,
        "intake_user_css_id" => @sc_task.appeal.intake.user.css_id,
        "intake_user_station_id" => @sc_task.appeal.intake.user.station_id,
        "disposition" => nil,
        "decision_user_name" => nil,
        "decision_user_css_id" => nil,
        "decision_user_station_id" => nil,
        "claimant_name" => @sc_task.appeal.claimant.name,
        "task_status" => @sc_task.status,
        "request_issue_benefit_type" => "vha",
        "days_waiting" => (Time.zone.today - Date.parse(@sc_task.assigned_at.iso8601)).to_i
      )
    end
    let(:imr_hlr_expectation) do
      a_hash_including(
        "requested_issue_type" => "Medical and Dental Care Reimbursement",
        "requested_issue_description" => "Reimbursement note description",
        "remove_original_issue" => false,
        "modification_request_reason" => "I edited this request.",
        "request_type" => "addition",
        "issue_modification_request_status" => "assigned",
        "decision_review_type" => "HigherLevelReview"
      )
    end
    let(:imr_sc_expectation) do
      a_hash_including(
        "requested_issue_type" => "Medical and Dental Care Reimbursement",
        "requested_issue_description" => "Reimbursement note description",
        "remove_original_issue" => false,
        "modification_request_reason" => "I edited this request.",
        "request_type" => "addition",
        "issue_modification_request_status" => "assigned",
        "decision_reason" => nil,
        "decision_review_type" => "SupplementalClaim"
      )
    end
    let(:remand_task_1_ri_1_expectation) do
      a_hash_including(
        "nonrating_issue_category" => "Clothing Allowance",
        "nonrating_issue_description" => "This is a Clothing Allowance issue",
        "task_id" => @remand_task.id,
        "veteran_file_number" => @remand_task.appeal.veteran_file_number,
        "intake_user_name" => nil,
        "intake_user_css_id" => nil,
        "intake_user_station_id" => nil,
        "disposition" => nil,
        "decision_user_name" => nil,
        "decision_user_css_id" => nil,
        "decision_user_station_id" => nil,
        "claimant_name" => @remand_task.appeal.claimant.name,
        "task_status" => @remand_task.status,
        "request_issue_benefit_type" => "vha",
        "days_waiting" => (Time.zone.today - Date.parse(@remand_task.assigned_at.iso8601)).to_i
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

    before(:all) do
      # Make sure the previous data from the before alls is cleaned up.
      Task.delete_all

      @hlr_task = create(:higher_level_review_vha_task_with_decision)
      @hlr_task2 = create(:higher_level_review_vha_task)
      @sc_task = create(:supplemental_claim_vha_task, appeal: create(:supplemental_claim,
                                                                     :with_vha_issue,
                                                                     :with_intake,
                                                                     benefit_type: "vha",
                                                                     claimant_type: :dependent_claimant))
      @remand_task = create(:remand_vha_task,
                            appeal: create(:remand, benefit_type: "vha", claimant_type: :dependent_claimant))
      @hlr_task_with_imr = create(:issue_modification_request,
                                  :with_higher_level_review,
                                  :edit_of_request,
                                  nonrating_issue_category: "Medical and Dental Care Reimbursement",
                                  nonrating_issue_description: "Reimbursement note description")
      @sc_task_with_imr = create(:issue_modification_request,
                                 :with_supplemental_claim,
                                 :edit_of_request,
                                 nonrating_issue_category: "Medical and Dental Care Reimbursement",
                                 nonrating_issue_description: "Reimbursement note description")

      @decision_issue = create(:decision_issue, disposition: "denied", benefit_type: @hlr_task.appeal.benefit_type)
      @intake_user = create(:user, full_name: "Alexander Dewitt", css_id: "ALEXVHA", station_id: "103")
      @decision_user = create(:user, full_name: "Gaius Baelsar", css_id: "GAIUSVHA", station_id: "104")

      issue = create(:request_issue,
                     nonrating_issue_category: "CHAMPVA",
                     nonrating_issue_description: "This is a CHAMPVA issue",
                     benefit_type: "vha")
      issue2 = create(:request_issue,
                      nonrating_issue_category: "Camp Lejune Family Member",
                      nonrating_issue_description: "This is a Camp Lejune issue",
                      benefit_type: "vha")
      @hlr_task.appeal.request_issues << issue
      @hlr_task2.appeal.request_issues << issue2
      # Create a request issue for the remand task
      create(:request_issue,
             nonrating_issue_category: "Clothing Allowance",
             nonrating_issue_description: "This is a Clothing Allowance issue",
             benefit_type: "vha",
             decision_review: @remand_task.appeal)

      # Add a different intake user to the second hlr task for data differences
      second_intake = @hlr_task2.appeal.intake
      second_intake.user = @intake_user
      second_intake.save

      # Add a couple of dispostions one here and one through the factory, to the first hlr task
      @decision_issue.request_issues << issue
      @hlr_task.appeal.decision_issues << @decision_issue
      @hlr_task.appeal.save

      # Set the assigned at for days waiting filtering for hlr_task2
      @hlr_task2.assigned_at = 5.days.ago
      @hlr_task2.save

      # Set up assigned at for days waiting filtering for hlr_task1
      PaperTrail.request(enabled: false) do
        @hlr_task.assigned_at = 10.days.ago
        @hlr_task.save
      end

      # Set the whodunnnit of the completed version status to the decision user
      version = @hlr_task.versions.first
      version.whodunnit = @decision_user.id.to_s
      version.save
    end

    subject { business_line.change_history_rows(change_history_filters) }

    context "without filters" do
      it "should return all rows" do
        expect(subject.count).to eq 8
        expect(subject.entries).to include(*all_expectations)
      end
    end

    context "with task_id filter" do
      context "with multiple task ids" do
        let(:change_history_filters) { { task_id: [@hlr_task.id, @sc_task.id, @remand_task.id] } }

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

      let(:change_history_filters) { { task_id: @hlr_task.id } }

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
          expect(subject.entries.count).to eq(2)
          expect(subject.entries).to include(sc_task_1_ri_1_expectation)
        end
      end

      context "Higher-Level Review claim filter" do
        let(:change_history_filters) { { claim_type: "HigherLevelReview" } }

        it "should only return rows for the filtered claim type" do
          expect(subject.entries.count).to eq(5)
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

    context "with task status filter pending" do
      let(:change_history_filters) { { task_status: ["pending"] } }

      it "should only return rows for the filtered status types" do
        expect(subject.entries.count).to eq(2)
        expect(subject.entries).to include(
          imr_hlr_expectation,
          imr_sc_expectation
        )
      end
    end

    context "with task status filter pending and completed" do
      let(:change_history_filters) { { task_status: %w[pending completed] } }

      it "should only return rows for the filtered status types" do
        expect(subject.entries.count).to eq(4)
        expect(subject.entries).to include(
          hlr_task_1_ri_1_expectation,
          hlr_task_1_ri_2_expectation,
          imr_hlr_expectation,
          imr_sc_expectation
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
          expect(subject.entries.count).to eq(6)
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
            expect(subject.entries.count).to eq(7)
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

      context "with a single disposition filter and task status pending" do
        let(:change_history_filters) { { dispositions: ["denied"], task_status: ["pending"] } }

        it "should only not return any row since pending task cannot have disposition" do
          expect(subject.entries.count).to eq(0)
        end
      end
    end

    context "with issue types filter" do
      context "with multiple issue type filters" do
        let(:change_history_filters) { { issue_types: ["Beneficiary Travel", "CHAMPVA"] } }

        it "should only return rows for the filtered issue type values" do
          expect(subject.entries.count).to eq(3)
          expect(subject.entries).to include(
            hlr_task_1_ri_2_expectation,
            sc_task_1_ri_1_expectation
          )
        end
      end

      context "with a single issue type filter" do
        let(:change_history_filters) { { issue_types: ["Caregiver | Other"] } }

        it "should only return rows for the filtered issue type values" do
          expect(subject.entries.count).to eq(3)
          expect(subject.entries).to include(
            hlr_task_1_ri_1_expectation,
            hlr_task_2_ri_1_expectation
          )
        end
      end

      context "with a single issue type filter and pending task status" do
        let(:change_history_filters) { { issue_types: ["Caregiver | Other"], task_status: ["pending"] } }

        it "should only return rows for the filtered issue type values" do
          expect(subject.entries.count).to eq(1)
          expect(subject.entries).to include(imr_hlr_expectation)
        end
      end
    end

    context "with days waiting filter" do
      context "< filter" do
        let(:change_history_filters) { { days_waiting: { number_of_days: 6, operator: "<" } } }

        it "should only return rows that are under the filtered days waiting value" do
          expect(subject.entries.count).to eq(4)
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
          expect(subject.entries.count).to eq(5)
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
        let(:change_history_filters) { { personnel: [@intake_user.css_id, @decision_user.css_id] } }

        it "only return rows where either an intake, decisions, or updates user matches the  css_ids" do
          expect(subject.entries.count).to eq(4)
          expect(subject.entries).to include(
            *(all_expectations - [sc_task_1_ri_1_expectation] - [remand_task_1_ri_1_expectation])
          )
        end
      end

      context "when filtering by a single css id" do
        let(:change_history_filters) { { personnel: [@intake_user.css_id] } }

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
        let(:change_history_filters) { { issue_types: ["Caregiver | Other"], task_id: @hlr_task.id } }

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
          expect(subject.entries.count).to eq(2)
          expect(subject.entries).to include(sc_task_1_ri_1_expectation)
        end
      end

      context "multiple issue types and claim type and task status pending" do
        let(:change_history_filters) do
          { issue_types: ["Beneficiary Travel", "CHAMPVA"], claim_type: "SupplementalClaim", task_status: ["pending"] }
        end

        it "should only return rows that match both filters" do
          expect(subject.entries.count).to eq(1)
          expect(subject.entries).to include(imr_sc_expectation)
        end
      end
    end
  end

  def add_veteran_and_request_issues_to_decision_reviews(tasks, veteran, business_line)
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
