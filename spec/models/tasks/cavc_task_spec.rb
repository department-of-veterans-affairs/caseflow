# frozen_string_literal: true

describe CavcTask, :postgres do
  describe ".create" do
    subject { described_class.create(appeal: appeal, parent: parent_task) }
    let(:appeal) { create(:appeal) }
    let(:parent_task) { create(:distribution_task, appeal: appeal) }

    context "parent is DistributionTask" do
      it "creates task" do
        new_task = subject
        expect(new_task.valid?)
        expect(new_task.errors.messages[:parent]).to be_empty

        expect(appeal.tasks).to include new_task
        expect(parent_task.children).to include new_task

        expect(new_task.assigned_to).to eq Bva.singleton
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

  describe "#available_actions" do
    let(:user) { create(:user) }
    let(:cavc_task) { create(:cavc_task) }
    it "returns empty" do
      binding.pry
      expect(cavc_task.available_actions(user)).to be_empty
    end
  end

end
