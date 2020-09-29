# frozen_string_literal: true

describe CavcTask, :postgres do
  describe ".create" do
    subject { described_class.create(appeal: appeal, parent: parent_task) }
    let(:appeal) { create(:appeal) }
    let!(:parent_task) { create(:distribution_task, appeal: appeal) }

    context "parent is DistributionTask" do
      it "creates task" do
        new_task = subject
        expect(new_task.valid?)
        expect(new_task.errors.messages[:parent]).to be_empty

        expect(appeal.tasks).to include new_task
        expect(parent_task.children).to include new_task

        expect(new_task.assigned_to).to eq Bva.singleton
        expect(new_task.label).to eq "All CAVC-related tasks"
        expect(new_task.default_instructions).to eq [COPY::CAVC_TASK_DEFAULT_INSTRUCTIONS]
      end
    end

    context "parent is not a DistributionTask" do
      let(:parent_task) { create(:root_task) }
      it "fails to create task" do
        new_task = subject
        expect(new_task.invalid?)
        expect(new_task.errors.messages[:parent]).to include("parent should be a DistributionTask")
      end
    end

    context "parent is nil" do
      let(:parent_task) { nil }
      it "fails to create task" do
        new_task = subject
        expect(new_task.invalid?)
        expect(new_task.errors.messages[:parent]).to include("can't be blank")
      end
    end
  end

  describe "FactoryBot.create(:cavc_task) with different arguments" do
    context "appeal is provided" do
      let(:appeal) { create(:appeal) }
      let!(:parent_task) { create(:distribution_task, appeal: appeal) }
      let!(:cavc_task) { create(:cavc_task, appeal: appeal) }
      it "finds existing distribution_task to use as parent" do
        expect(Appeal.count).to eq 1
        expect(RootTask.count).to eq 1
        expect(DistributionTask.count).to eq 1
        expect(CavcTask.count).to eq 1
      end
    end
    context "parent task is provided" do
      let(:parent_task) { create(:distribution_task) }
      let!(:cavc_task) { create(:cavc_task, parent: parent_task) }
      it "uses existing distribution_task" do
        expect(Appeal.count).to eq 1
        expect(RootTask.count).to eq 1
        expect(DistributionTask.count).to eq 1
        expect(CavcTask.count).to eq 1
      end
    end
    context "nothing is provided" do
      let!(:cavc_task) { create(:cavc_task) }
      it "creates realistic task tree" do
        expect(Appeal.count).to eq 1
        expect(RootTask.count).to eq 1
        expect(DistributionTask.count).to eq 1
        expect(CavcTask.count).to eq 1
      end
    end
  end

  describe "#available_actions" do
    let(:user) { create(:user) }
    let(:cavc_task) { create(:cavc_task) }
    it "returns empty" do
      expect(cavc_task.available_actions(user)).to be_empty
    end
  end

  context "closing child tasks" do
    let(:user) { create(:user) }
    let(:cavc_task) { create(:cavc_task) }
    let!(:child_task) { create(:ama_task, parent: cavc_task) }
    context "as complete" do
      it "completes parent CavcTask" do
        child_task.completed!
        expect(cavc_task.closed?)
        expect(cavc_task.status).to eq "completed"
      end
    end
    context "as cancelled" do
      it "cancels parent CavcTask" do
        child_task.cancelled!
        expect(cavc_task.closed?)
        expect(cavc_task.status).to eq "cancelled"
      end
    end
    context "has multiple children" do
      let!(:child_task2) { create(:ama_task, parent: cavc_task) }
      it "leaves parent CavcTask open when completing 1 child" do
        child_task.completed!
        expect(cavc_task.open?)
        expect(cavc_task.status).to eq "on_hold"
      end
      it "leaves parent CavcTask open when cancelling 1 child" do
        child_task.cancelled!
        expect(cavc_task.open?)
        expect(cavc_task.status).to eq "on_hold"
      end
      it "closes parent CavcTask when closing last open child" do
        child_task.cancelled!
        expect(cavc_task.open?)
        expect(cavc_task.status).to eq "on_hold"
        child_task2.completed!
        expect(cavc_task.closed?)
        expect(cavc_task.status).to eq "completed"
      end
    end
  end
end
