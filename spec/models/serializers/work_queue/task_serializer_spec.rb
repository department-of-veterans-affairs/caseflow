# frozen_string_literal: true

describe WorkQueue::TaskSerializer, :postgres do
  let(:now) { Time.utc(2018, 4, 24, 12, 0, 0) }
  let(:user) { create(:user) }
  let!(:parent) { create(:ama_task, assigned_to: user) }
  let(:days_on_hold) { 18 }

  describe "#as_json" do
    subject { described_class.new(parent).serializable_hash[:data][:attributes] }

    before do
      Timecop.freeze(now)
    end

    after do
      Timecop.return
    end

    context "with a timed hold task" do
      it "renders the correct values for a task with a child TimedHoldTask" do
        TimedHoldTask.create!(appeal: parent.appeal, assigned_to: user, days_on_hold: days_on_hold, parent: parent)

        expect(subject[:placed_on_hold_at]).to eq now
        expect(subject[:on_hold_duration]).to eq days_on_hold
      end
    end
  end

  context "inactive organization assignee" do
    subject { described_class.new(child).serializable_hash[:data][:attributes] }
    let(:inactive_org) { create(:private_bar, status: :inactive) }
    let!(:child) { create(:ama_task, parent: parent, assigned_to: inactive_org).reload }
    it "serializes assignee information" do
      expect(child.assigned_to).to eq nil
      expect(subject[:assigned_to][:id]).to eq inactive_org.id
      expect(subject[:assigned_to][:name]).to eq inactive_org.name
      expect(subject[:assignee_name]).to eq inactive_org.name
      expect(subject[:assigned_to][:status]).to eq "inactive"
    end
  end

  describe "the attribute timer_ends_at" do
    subject { described_class.new(task).serializable_hash[:data][:attributes] }

    context "an EvidenceSubmissionWindowTask" do
      let(:task) { EvidenceSubmissionWindowTask.create!(appeal: parent.appeal, assigned_to: user, parent: parent) }
      it "returns a timer_ends_at Date value" do
        expect(subject[:timer_ends_at]).not_to eq(nil)
      end
    end

    context "a task that is not an EvidenceSubmissionWindowTask" do
      let(:task) { create(:distribution_task) }
      it "returns nil for timer_ends_at" do
        expect(subject[:timer_ends_at]).to eq(nil)
      end
    end
  end
end
