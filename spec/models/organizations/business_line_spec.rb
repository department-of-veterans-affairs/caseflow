# frozen_string_literal: true

require "rspec"

describe "BusinessLine" do
  describe "#in_progress_tasks" do
    let(:business_line) { create(:business_line) }
    let(:user) { create(:user) }

    let(:appeal) { create(:appeal) }
    let!(:request_issues) do
      create(:request_issue, decision_review: appeal)
    end

    let!(:first_open_task) do
      create(
        :higher_level_review_task, :in_progress,
        assigned_to: business_line,
        appeal: appeal
      )
    end
    let!(:second_open_task) do
      create(
        :ama_colocated_task, :assigned,
        assigned_to: business_line,
        appeal: appeal
      )
    end
    let(:closed_task) do
      create(
        :veteran_record_request_task, :completed,
        assigned_to: business_line,
        appeal: appeal
      )
    end

    before do
      business_line.add_user(user)
    end

    subject { business_line.in_progress_tasks(user) }

    it "loads open tasks" do
      expect(subject).to contain_exactly(first_open_task, second_open_task)
    end
  end
end
