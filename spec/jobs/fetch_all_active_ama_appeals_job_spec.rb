# frozen_string_literal: true

describe FetchAllActiveAmaAppealsJob, type: :job do
  include ActiveJob::TestHelper
  subject { FetchAllActiveAmaAppealsJob.new }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "is in the correct queue" do
    queue_name = "caseflow_test_low_priority"
    expect(subject.queue_name).to eq(queue_name)
  end

  describe ".perform" do
    it "returns an array of all active ama appeals" do
      expect(subject).to receive(:find_active_ama_appeals)
      subject.perform
    end
  end
    
  describe "find_active_ama_appeals" do
    let!(:ama_task) do
      Array.new(1) { create(:ama_task) }
    end
    context "when database has an appeal" do
      it "should return an array with the data of the appeal" do
      expect(subject.send(:find_active_ama_appeals)).to eq(ama_task.map(&:appeal))
    end
    
    context "when database has an appeal in on_hold status" do
      before do
        ama_task.each { |t| t.update!(status: Constants.TASK_STATUSES.on_hold) }
      end
      it "should return an array with the appeal tied to that task" do
        expect(subject.send(:find_active_ama_appeals)).to eq(ama_task.map(&:appeal))
      end
    end
    
    context "when database has an appeal in in_progress status" do
      before do
        ama_task.each { |t| t.update!(status: Constants.TASK_STATUSES.in_progress) }
      end
      it "should return an array with the appeal tied to that task" do
        expect(subject.send(:find_active_ama_appeals)).to eq(ama_task.map(&:appeal))
      end
    end

    context "when database has an appeal in cancelled status" do
      before do
        ama_task.each { |t| t.update!(status: Constants.TASK_STATUSES.cancelled) }
      end
      it "should not return the appeal tied to that task" do
        expect(subject.send(:find_active_ama_appeals)).not_to eq(ama_task.map(&:appeal))
      end
    end

    context "when database has an appeal in completed status" do
      before do
        ama_task.each { |t| t.update!(status: Constants.TASK_STATUSES.completed) }
      end
      it "should not return the appeal tied to that task" do
        expect(subject.send(:find_active_ama_appeals)).not_to eq(ama_task.map(&:appeal))
      end
    end

    context "When database has a task for an appeal with a non nil closed_at attribute" do
      before do
        ama_task.each { |t| t.update!(closed_at: Time.zone.now) }
      end
      it "should not return the appeal tied to that task" do
        expect(subject.send(:find_active_ama_appeals)).not_to include(ama_task.map(&:appeal))
      end
    end
  end
end
end
