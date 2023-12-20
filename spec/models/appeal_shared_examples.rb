# frozen_string_literal: true

# Shared examples for AMA and legacy appeals

shared_examples "toggle overtime" do
  before { FeatureToggle.enable!(:overtime_revamp) }

  after { FeatureToggle.disable!(:overtime_revamp) }

  it "updates #overtime?" do
    expect(appeal.overtime?).to be(false)

    appeal.overtime = true
    expect(appeal.overtime?).to be(true)

    appeal.overtime = false
    expect(appeal.overtime?).to be(false)
  end
end

shared_examples "latest informal hearing presentation task" do
  shared_examples "the appeal has an ihp task" do
    it "returns the ihp task" do
      expect(subject).to eq(ihp_task)
    end

    context "when the task is completed" do
      before { ihp_task.completed! }

      it "returns the ihp task" do
        expect(subject).to eq(ihp_task)
      end
    end

    context "when the task is cancelled" do
      before { ihp_task.cancelled! }

      it { expect(subject).to eq(nil) }
    end
  end

  before { allow_any_instance_of(Colocated).to receive(:next_assignee).and_return(nil) }

  let!(:root_task) { create(:root_task, appeal: appeal) }

  subject { appeal.latest_informal_hearing_presentation_task }

  context "when the appeal has no informal hearing presentation tasks" do
    it { expect(subject).to eq(nil) }
  end

  context "when the appeal has an InformalHearingPresentationTask" do
    let!(:ihp_task) { create(:informal_hearing_presentation_task, appeal: appeal) }

    it_behaves_like "the appeal has an ihp task"
  end

  context "when the appeal has an InformalHearingPresentationTask" do
    let!(:ihp_task) { create(:ama_colocated_task, :ihp, appeal: appeal) }

    it_behaves_like "the appeal has an ihp task"
  end

  context "when there are multiple ihp tasks on the appeal" do
    shared_examples "multiple ihp tasks" do
      it "returns the more recent ihp task" do
        expect(subject).to eq most_recent_task
      end
    end

    context "when one task was completed more recently than the other" do
      let!(:most_recent_task) { create(:ama_colocated_task, :ihp, appeal: appeal, closed_at: 1.day.ago) }
      let!(:older_task) { create(:ama_colocated_task, :ihp, appeal: appeal, closed_at: 2.days.ago) }

      it_behaves_like "multiple ihp tasks"

      context "when the recently completed one was assigned before the less recently completed task" do
        before do
          most_recent_task.update!(assigned_at: 2.days.ago)
          older_task.update!(assigned_at: 1.day.ago)
        end

        it_behaves_like "multiple ihp tasks"
      end

      context "when both were cancelled" do
        before { [most_recent_task, older_task].each(&:cancelled!) }

        it { expect(subject).to eq(nil) }
      end
    end

    context "when one task was assigned more recently than the other" do
      let!(:most_recent_task) { create(:ama_colocated_task, :ihp, appeal: appeal, assigned_at: 1.day.ago) }
      let!(:older_task) { create(:ama_colocated_task, :ihp, appeal: appeal, assigned_at: 2.days.ago) }

      it_behaves_like "multiple ihp tasks"
    end

    context "when one task was assigned more recently than the other was closed" do
      let!(:most_recent_task) { create(:ama_colocated_task, :ihp, appeal: appeal, assigned_at: 1.day.ago) }
      let!(:older_task) { create(:ama_colocated_task, :ihp, appeal: appeal, closed_at: 2.days.ago) }

      it_behaves_like "multiple ihp tasks"
    end
  end
end
