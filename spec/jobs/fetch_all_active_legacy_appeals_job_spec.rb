# frozen_string_literal: true

describe FetchAllActiveLegacyAppealsJob do
  subject { FetchAllActiveLegacyAppealsJob.new }
  describe ".perform" do
    it "returns an array of all active legacy appeals" do
      expect(subject).to receive(:find_active_legacy_appeals)
      subject.perform
    end
  end
  describe "find_active_legacy_appeals" do
    let!(:legacy_task) do
      Array.new(1) { create(:task, type: "RootTask") }
    end
    let!(:ama_task) do
      Array.new(1) { create(:ama_task, type: "RootTask") }
    end
    context "when database has a RootTask for a Legacy Appeal with an assigned status" do
      it "should return an array with the appeal tied to that task" do
        expect(subject.send(:find_active_legacy_appeals)).to eq(legacy_task.map(&:appeal))
      end
    end
    context "when database has a RootTask for a Legacy Appeal with an on_hold status" do
      before do
        legacy_task.each { |t| t.update!(status: Constants.TASK_STATUSES.on_hold) }
      end
      it "should return an array with the appeal tied to that task" do
        expect(subject.send(:find_active_legacy_appeals)).to eq(legacy_task.map(&:appeal))
      end
    end
    context "when database has a RootTask for a Legacy Appeal with an in_progress status" do
      before do
        legacy_task.each { |t| t.update!(status: Constants.TASK_STATUSES.in_progress) }
      end
      it "should return an array with the appeal tied to that task" do
        expect(subject.send(:find_active_legacy_appeals)).to eq(legacy_task.map(&:appeal))
      end
    end
    context "when database has a RootTask for a Legacy Appeal with a cancelled status" do
      before do
        legacy_task.each { |t| t.update!(status: Constants.TASK_STATUSES.cancelled) }
      end
      it "should not return the appeal tied to that task" do
        expect(subject.send(:find_active_legacy_appeals)).not_to include(legacy_task.map(&:appeal))
      end
    end
    context "when database has a RootTask for a Legacy Appeal with a completed status" do
      before do
        legacy_task.each { |t| t.update!(status: Constants.TASK_STATUSES.completed) }
      end
      it "should not return the appeal tied to that task" do
        expect(subject.send(:find_active_legacy_appeals)).not_to include(legacy_task.map(&:appeal))
      end
    end
    context "when database has a Non-RootTask for a Legacy Appeal" do
      before do
        legacy_task.each { |t| t.update!(type: "NonRootTask") }
      end
      it "should not return the appeal tied to that task" do
        expect(subject.send(:find_active_legacy_appeals)).not_to include(legacy_task.map(&:appeal))
      end
    end
    context "when database has a task for a Legacy Appeal with a non nil closed_at attribute" do
      before do
        legacy_task.each { |t| t.update!(closed_at: Time.zone.now) }
      end
      it "should not return the appeal tied to that task" do
        expect(subject.send(:find_active_legacy_appeals)).not_to include(legacy_task.map(&:appeal))
      end
    end
    context "when database has a RootTask for an AMA Appeal" do
      it "should not return the appeal tied to that task" do
        expect(subject.send(:find_active_legacy_appeals)).not_to include(ama_task.map(&:appeal))
      end
    end
  end
end
