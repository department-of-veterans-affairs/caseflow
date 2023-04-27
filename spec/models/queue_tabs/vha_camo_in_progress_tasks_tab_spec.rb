# frozen_string_literal: true

describe VhaCamoInProgressTasksTab, :postgres do
  let(:tab) { VhaCamoInProgressTasksTab.new(params) }
  let(:params) do
    { assignee: assignee }
  end
  let(:assignee) { VhaCamo.singleton }
  let(:vha_po_org) { VhaProgramOffice.create!(name: "Vha Program Office", url: "vha-po") }
  let(:visn_org) { VhaRegionalOffice.create!(name: "Vha Regional Office", url: "vha-visn") }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating a VhaCamoInProgressTasksTab" do
      let(:params) { { assignee: VhaCamo.singleton } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(8)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks in progress at the PO or VISN level" do
      # in progress tab
      # PO assigned AssessDocumentationTask
      let!(:camo_po_assigned_tasks) { create_list(:vha_document_search_task, 3, :assigned, assigned_to: assignee) }
      let!(:vha_po_assigned) do
        camo_po_assigned_tasks.map do |task|
          create(:assess_documentation_task, parent: task, assigned_to: vha_po_org)
          task.children
        end.flatten
      end
      # VISN assigned AssessDocumentationTask
      let!(:camo_visn_assigned_tasks) { create_list(:vha_document_search_task, 3, :assigned, assigned_to: assignee) }
      let!(:vha_visn_assigned) do
        camo_visn_assigned_tasks.map do |task|
          create(:assess_documentation_task, parent: task, assigned_to: visn_org)
          task.children
        end.flatten
      end
      # PO in_progress AssessDocumentationTask
      let!(:camo_po_in_progress_tasks) { create_list(:vha_document_search_task, 3, :assigned, assigned_to: assignee) }
      let!(:vha_po_in_progress) do
        camo_po_in_progress_tasks.map do |task|
          create(:assess_documentation_task, parent: task, assigned_to: vha_po_org)
          task.descendants.each(&:in_progress!)
          task.on_hold!
          task.children
        end.flatten
      end
      # VISN in_progress AssessDocumentationTask
      let!(:camo_visn_in_progress_tasks) { create_list(:vha_document_search_task, 3, :assigned, assigned_to: assignee) }
      let!(:vha_visn_in_progress) do
        camo_visn_in_progress_tasks.map do |task|
          create(:assess_documentation_task, parent: task, assigned_to: visn_org)
          task.descendants.each(&:in_progress!)
          task.on_hold!
          task.children
        end.flatten
      end

      it "returns all the in progress tasks" do
        expect(subject).to include(*vha_po_assigned, *vha_visn_assigned, *vha_po_in_progress, *vha_visn_in_progress)
      end
    end

    context "when there are tasks on hold at the PO or VISN level" do
      # on hold tab
      # PO on_hold AssessDocumentationTask
      let!(:camo_po_on_hold_tasks) { create_list(:vha_document_search_task, 3, :assigned, assigned_to: assignee) }
      let!(:vha_po_on_hold) do
        camo_po_on_hold_tasks.map do |task|
          create(:assess_documentation_task, parent: task, assigned_to: vha_po_org)
          create(:timed_hold_task, parent: task, assigned_to: vha_po_org)
          task.descendants.each(&:on_hold!)
          task.children
        end.flatten
      end
      # VISN on_hold AssessDocumentationTask
      let!(:camo_visn_on_hold_tasks) { create_list(:vha_document_search_task, 3, :assigned, assigned_to: assignee) }
      let!(:vha_visn_on_hold) do
        camo_visn_on_hold_tasks.map do |task|
          create(:assess_documentation_task, parent: task, assigned_to: visn_org)
          create(:timed_hold_task, parent: task, assigned_to: visn_org)
          task.descendants.each(&:on_hold!)
          task.children
        end.flatten
      end

      it "does not return tasks on hold at the PO or VISN level" do
        expect(subject).to_not include(*vha_po_on_hold, *vha_visn_on_hold)
      end
    end

    context "when there are tasks assigned to CAMO" do
      # assigned tab
      # assigned VhaDocumentSearchTask
      let!(:vha_camo_assigned) { create_list(:vha_document_search_task, 4, :assigned, assigned_to: assignee) }
      # PO completed AssessDocumentationTask
      let!(:camo_po_completed_tasks) { create_list(:vha_document_search_task, 3, :assigned, assigned_to: assignee) }
      let!(:vha_po_completed) do
        camo_po_completed_tasks.map do |task|
          create(:assess_documentation_task, parent: task, assigned_to: vha_po_org)
          task.descendants.each(&:completed!)
          task.assigned!
          task.children
        end.flatten
      end
      # VISN completed AssessDocumentationTask
      let!(:camo_visn_completed_tasks) { create_list(:vha_document_search_task, 3, :assigned, assigned_to: assignee) }
      let!(:vha_visn_completed) do
        camo_visn_completed_tasks.map do |task|
          create(:assess_documentation_task, parent: task, assigned_to: visn_org)
          task.descendants.each(&:completed!)
          task.assigned!
          task.children
        end.flatten
      end

      it "does not return CAMO's assigned tasks" do
        expect(subject).to_not include(*vha_camo_assigned, *vha_po_completed, *vha_visn_completed)
      end
    end

    context "when there are tasks completed by CAMO" do
      # completed tab
      # completed VhaDocumentSearchTask
      let!(:vha_camo_completed) { create_list(:vha_document_search_task, 4, :completed, assigned_to: assignee) }

      it "does not return CAMO's completed tasks" do
        expect(subject).to_not include(*vha_camo_completed)
      end
    end

    context "when the assignee is not a CAMO user" do
      let(:assignee) { create(:user) }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end
  end
end
