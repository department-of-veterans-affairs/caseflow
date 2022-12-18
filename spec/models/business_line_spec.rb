# frozen_string_literal: true

describe BusinessLine do
  let(:business_line) { create(:business_line, name: "VHA", url: "vha") }
  let(:veteran) { create(:veteran) }

  describe ".tasks_url" do
    it { expect(business_line.tasks_url).to eq "/decision_reviews/vha" }
  end

  describe ".in_progress_tasks" do
    let!(:decision_review_tasks_on_active_decision_reviews) do
      tasks = create_list(:higher_level_review_task, 5, assigned_to: business_line)

      tasks.each do |task|
        task.appeal.update!(veteran_file_number: veteran.file_number)
        create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: business_line.url)
      end

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
          closed_at: Time.zone.now,
          closed_status: "decided"
        )
      end

      tasks
    end

    let!(:veteran_record_request_on_active_appeals) do
      tasks = create_list(:veteran_record_request_task, 5, assigned_to: business_line)

      tasks.each do |task|
        task.appeal.update!(veteran_file_number: veteran.file_number)
        create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: business_line.url)
      end

      tasks
    end

    let!(:veteran_record_request_on_inactive_appeals) do
      create_list(:veteran_record_request_task, 5, assigned_to: business_line)
    end

    subject { business_line.in_progress_tasks }

    it "tasks are acquired with a single query (no N+1 queries)" do
      sql_track_data = SqlTracker.track { subject }

      # A single query should be performed, opposed to 1 + N queries where N is the
      # number of tasks created for this test section (ex: 25).
      expect(
        sql_track_data.values.sum { |query_data| query_data[:count] }
      ).to eq 1
    end

    context "With the :board_grant_effectuation_task FeatureToggle enabled" do
      before { FeatureToggle.enable!(:board_grant_effectuation_task) }
      after { FeatureToggle.disable!(:board_grant_effectuation_task) }

      it "All tasks associated with active decision reviews and BoardGrantEffectuationTasks are included" do
        expect(subject.size).to eq 15
        expect(subject.map(&:id)).to match_array(
          (veteran_record_request_on_active_appeals +
            board_grant_effectuation_tasks +
            decision_review_tasks_on_active_decision_reviews
          ).pluck(:id)
        )
      end
    end

    context "With the :board_grant_effectuation_task FeatureToggle disabled" do
      before { FeatureToggle.disable!(:board_grant_effectuation_task) }

      it "All tasks associated with active decision reviews are included, but not BoardGrantEffectuationTasks" do
        expect(subject.size).to eq 10
        expect(subject.map(&:id)).to match_array(
          (veteran_record_request_on_active_appeals +
            decision_review_tasks_on_active_decision_reviews
          ).pluck(:id)
        )
      end
    end
  end

  describe ".completed_tasks" do
    let!(:open_decision_review_tasks) do
      create_list(:higher_level_review_task, 5, assigned_to: business_line)
    end

    let!(:completed_decision_review_tasks) do
      tasks = create_list(:higher_level_review_task, 5, assigned_to: business_line)

      tasks.each(&:completed!)

      tasks
    end

    let!(:open_board_grant_effectuation_tasks) do
      create_list(:board_grant_effectuation_task, 5, assigned_to: business_line)
    end

    let!(:completed_board_grant_effectuation_tasks) do
      tasks = create_list(:board_grant_effectuation_task, 5, assigned_to: business_line)

      tasks.each(&:completed!)

      tasks
    end

    let!(:open_veteran_record_requests) do
      create_list(:veteran_record_request_task, 5, assigned_to: business_line)
    end

    let!(:completed_veteran_record_requests) do
      tasks = create_list(:veteran_record_request_task, 5, assigned_to: business_line)

      tasks.each(&:completed!)

      tasks
    end

    subject { business_line.completed_tasks }

    it "All completed tasks are included in results" do
      expect(subject.size).to eq 15
      expect(subject.map(&:id)).to match_array(
        (completed_decision_review_tasks +
          completed_board_grant_effectuation_tasks +
          completed_veteran_record_requests
        ).pluck(:id)
      )
    end
  end
end
