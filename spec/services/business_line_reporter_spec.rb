require 'rspec'

describe 'BusinessLineReporter' do
  let(:business_line) { create(:business_line) }

  before do
    10.times do
      appeal = create(:appeal, :with_post_intake_tasks)
      ama_task = create(:ama_task, appeal: appeal, assigned_to: business_line)
      ama_task.completed!
    end
  end

  describe "#tasks" do
    subject { BusinessLineReporter.new(business_line).tasks }

    it "returns 10 items" do
      expect(subject.size).to eq 10
    end
  end

  describe "#as_csv" do
    # let(:appeal) { create(:appeal, :with_post_intake_tasks) }
    # let(:ama_task) { create(:ama_task, appeal: appeal, assigned_to: business_line) }
    # let(:foia_task) { create(:foia_task, appeal: appeal, assigned_to: business_line) }
    # let(:timed_hold_task) { create(:timed_hold_task, appeal: appeal, assigned_to: business_line) }
    # let(:esw_task) { create(:evidence_submission_window_task, appeal: appeal, assigned_to: business_line) }

    subject { BusinessLineReporter.new(business_line).as_csv }

    context "with several tasks" do
      it "doesn't run a bunch of n+1 queries" do
        expect(subject.split("\n").size).to eq 11 # 10 + header row
      end
    end
  end
end