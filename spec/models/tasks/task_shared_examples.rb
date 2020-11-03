# frozen_string_literal: true

shared_examples_for "task requiring specific parent" do
  context "parent is the expected type" do
    it "creates task" do
      new_task = subject
      expect(new_task.valid?)
      expect(new_task.errors.messages[:parent]).to be_empty

      expect(appeal.tasks).to include new_task
      expect(parent_task.children).to include new_task
    end
  end

  context "parent task is not the expected type" do
    let(:parent_task) { create(:root_task) }
    it "fails to create task" do
      new_task = subject
      expect(new_task.invalid?)
      expect(new_task.errors.messages[:parent]).to include("parent should be a #{parent_task_class.name}")
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
