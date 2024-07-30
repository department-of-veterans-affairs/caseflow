# frozen_string_literal: true

describe EducationEmoAssignedTasksTab, :postgres do
  let(:tab) { EducationEmoAssignedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:education_emo) }
  let(:education_rpo) { create(:education_rpo) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an EducationEmoAssignedTasksTab" do
      let(:params) { { assignee: create(:education_emo) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(6)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when the EMO sends an appeal to BVA Intake" do
      let!(:assignee_completed_task) { create(:education_document_search_task, :completed, assigned_to: assignee) }

      it("the PreDocketTask appears in the EMO assigned tab whenever
        BVA Intake has not taken any additional actions") do
        assignee_completed_task.parent.update!(status: Constants.TASK_STATUSES.assigned)

        expect(subject.count).to eq 1
        expect(subject.first.type).to eq "PreDocketTask"
      end

      it("the PreDocketTask appears once in the EMO assigned tab if it is assigned to BVA Intake
        even if there are multiple EducationDocumentSearchTasks child tasks") do
        parent_task = assignee_completed_task.parent

        emo_task = EducationDocumentSearchTask.create!(
          parent: parent_task,
          appeal: parent_task.appeal,
          assigned_at: Time.zone.now,
          assigned_to: assignee
        )

        emo_task.update!(status: Constants.TASK_STATUSES.completed)
        parent_task.update!(status: Constants.TASK_STATUSES.assigned)

        expect(subject.count).to eq 1
        expect(subject.first.type).to eq "PreDocketTask"
      end

      it("no task appears in the EMO assigned tab whenever BVA Intake dockets it") do
        assignee_completed_task.parent.update!(status: Constants.TASK_STATUSES.completed)

        expect(subject.count).to eq 0
      end

      it("no task appears in the EMO assigned tab whenever BVA Intake cancels it") do
        assignee_completed_task.parent.update!(status: Constants.TASK_STATUSES.cancelled)

        expect(subject.count).to eq 0
      end
    end

    context "when BVA Intake returns an appeal to the EMO" do
      let!(:original_edu_doc_search_task) { create(:education_document_search_task, :completed, assigned_to: assignee) }
      let!(:appeal) { original_edu_doc_search_task.appeal }
      let!(:new_edu_doc_search_task) do
        create(
          :education_document_search_task,
          :assigned,
          assigned_to: assignee,
          assigned_at: Time.zone.now,
          parent: original_edu_doc_search_task.parent
        )
      end

      it "the new EducationDocumentSearchTask appears in the unsassigned tab and
        the old EducationDocumentSearchTask is hidden from view" do
        expect(subject.count).to eq 0
      end
    end

    context "when the EMO sends the appeal to an RPO" do
      let!(:assignee_on_hold_tasks) do
        create_list(:education_document_search_task, 3, :assigned, assigned_to: assignee)
      end
      let!(:on_hold_tasks_children) do
        assignee_on_hold_tasks.map do |task|
          create(
            :education_assess_documentation_task,
            :in_progress,
            parent: task,
            assigned_at: Time.zone.now,
            assigned_to: education_rpo
          )
          task.update!(status: Constants.TASK_STATUSES.on_hold)
          task.children
        end.flatten
      end

      it "the tasks appear in the EMO's assigned tab while the RPO works on the appeal" do
        expect(subject.count).to eq 3
      end

      it "the tasks appear in the EMO's assigned tab even if they are in progress within an RPO" do
        on_hold_tasks_children.first.update!(status: Constants.TASK_STATUSES.in_progress)
        expect(subject.count).to eq 3
      end

      it "the appeal does not appear in the EMO's assigned tab if the RPO returns the appeal to the EMO" do
        task_returned = on_hold_tasks_children.first

        on_hold_tasks_children.first.update!(status: Constants.TASK_STATUSES.completed)
        on_hold_tasks_children.first.parent.update!(status: Constants.TASK_STATUSES.assigned)

        expect(subject.count).to eq 2
        expect(subject).not_to include task_returned
      end

      it "the appeal appears in the EMO's assigned tab when the RPO sends the appeal to BVA Intake directly" do
        on_hold_tasks_children.first.update!(status: Constants.TASK_STATUSES.completed)
        on_hold_tasks_children.first.parent.update!(status: Constants.TASK_STATUSES.completed)

        expect(subject.count).to eq 3
      end
    end
  end
end
