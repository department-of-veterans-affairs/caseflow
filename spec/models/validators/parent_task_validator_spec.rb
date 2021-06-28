# frozen_string_literal: true

describe ParentTaskValidator, :postgres do
  describe "#validate" do
    shared_examples "valid parent task type" do
      context "and the parent's task type is valid" do
        let(:parent_task_type) { :foia_task }

        it "produces no errors" do
          expect(subject.valid?).to be true
          expect(subject.errors.count).to eq 0
        end
      end
    end

    let(:parent_task_type) { :root_task }
    let(:appeal) { create(:appeal) }
    let(:assigned_to) { create(:user) }
    let(:parent_task) { create(parent_task_type, assigned_to: assigned_to, appeal: appeal) }

    subject { task_class.new(parent: parent_task, assigned_to: assigned_to, appeal: appeal) }

    context "when there is no valid parent task type" do
      class NoParentTypeTask < Task
        validates :parent, presence: true, parentTask: { task_type: nil }, on: :create
      end

      let(:task_class) { NoParentTypeTask }

      it_behaves_like "valid parent task type"
    end

    context "when there is one valid parent task type" do
      class OneParentTypeTask < Task
        validates :parent, presence: true, parentTask: { task_type: FoiaTask }, on: :create
      end

      let(:task_class) { OneParentTypeTask }

      it_behaves_like "valid parent task type"

      context "and the parent's task type is invalid" do
        it "fails validation" do
          expect(subject.valid?).to be false
          expect(subject.errors.count).to eq 1
          expect(subject.errors.messages[:parent].first).to eq "should be a FoiaTask"
        end
      end
    end

    context "when there are multiple valid parent task types" do
      class MultipleParentTypeTask < Task
        validates :parent, presence: true, parentTask: { task_types: [FoiaTask, MailTask] }, on: :create
      end

      let(:task_class) { MultipleParentTypeTask }

      it_behaves_like "valid parent task type"

      context "and the parent's task type is invalid" do
        it "fails validation" do
          expect(subject.valid?).to be false
          expect(subject.errors.count).to eq 1
          expect(subject.errors.messages[:parent].first).to eq "should be one of FoiaTask, MailTask"
        end
      end
    end
  end
end
