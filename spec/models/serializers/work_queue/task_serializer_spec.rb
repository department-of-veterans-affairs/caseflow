# frozen_string_literal: true

RSpec.shared_context("with restrict_poa_visibility feature toggle") do
  before { FeatureToggle.enable!(:restrict_poa_visibility) }
  after { FeatureToggle.disable!(:restrict_poa_visibility) }
end

RSpec.shared_examples("vso restricted") do
  it "does not include assigned_to" do
    expect(subject[:assigned_to]).to eq(nil)
  end
end

RSpec.shared_examples("unrestricted") do
  it "includes assigned_to" do
    expect(subject[:assigned_to]).to_not eq(nil)
  end
end

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

  describe "filtering of task attributes per policies" do
    subject { described_class.new(task, params: { user: user }).serializable_hash[:data][:attributes] }
    let(:task) { create(:ama_judge_decision_review_task) }

    context "as a vso user" do
      let(:user) { create(:user, :vso_role) }

      context "with feature toggle" do
        include_context "with restrict_poa_visibility feature toggle"

        it_should_behave_like "vso restricted"
      end

      context "without feature toggle" do
        it_should_behave_like "unrestricted"
      end
    end

    context "as a non-vso user" do
      let(:user) { create(:user, :vso_role) }

      it_should_behave_like "unrestricted"
    end
  end
end
