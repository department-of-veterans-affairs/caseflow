# frozen_string_literal: true

require "rspec"

describe "BusinessLineReporter" do
  let(:business_line) { create(:business_line) }

  let(:first_appeal) { create(:appeal, :with_post_intake_tasks) }
  let(:first_ama_task) { create(:ama_task, appeal: first_appeal, assigned_to: business_line) }

  let(:second_appeal) { create(:appeal, :with_post_intake_tasks) }
  let(:second_ama_task) { create(:ama_task, appeal: second_appeal, assigned_to: business_line) }

  let(:third_appeal) { create(:appeal, :with_post_intake_tasks) }
  let(:third_ama_task) { create(:ama_task, appeal: third_appeal, assigned_to: business_line) }

  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
    first_ama_task.completed!
    second_ama_task.completed!
  end

  describe "#tasks" do
    subject { BusinessLineReporter.new(business_line).tasks }

    it "returns the completed tasks" do
      expect(subject).to include(first_ama_task, second_ama_task)
    end

    it "does not return an open task" do
      expect(subject).to_not include(third_ama_task)
    end
  end

  describe "#as_csv" do
    subject { BusinessLineReporter.new(business_line).as_csv }

    # rubocop:disable Metrics/AbcSize
    def expected_csv
      <<~EOF
        business_line,appeal_id,appeal_type,claimant_name,request_issues_count,decision_issues_count,veteran_file_number,intake_user_id,task_type,task_id,tasks_url,task_assigned_to,created_at,closed_at
        #{business_line.name},#{first_appeal.id},Appeal,#{first_appeal.claimant.name},0,0,#{first_appeal.veteran.file_number},,Task,#{first_ama_task.id},https://appeals.cf.ds.va.gov#{business_line.tasks_url}/tasks/#{first_ama_task.id},#{first_ama_task.assigned_to.name},2020-01-01,2020-01-01
        #{business_line.name},#{second_appeal.id},Appeal,#{second_appeal.claimant.name},0,0,#{second_appeal.veteran.file_number},,Task,#{second_ama_task.id},https://appeals.cf.ds.va.gov#{business_line.tasks_url}/tasks/#{second_ama_task.id},#{second_ama_task.assigned_to.name},2020-01-01,2020-01-01
      EOF
    end
    # rubocop:enable Metrics/AbcSize

    context "with several tasks" do
      it "generates the expected csv" do
        expect(subject).to eq expected_csv
      end
    end
  end
end
