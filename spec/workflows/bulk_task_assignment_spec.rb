# frozen_string_literal: true

describe BulkTaskAssignment, :postgres do
  describe "#process" do
    let(:organization) { HearingsManagement.singleton }
    let!(:no_show_hearing_task1) do
      create(
        :no_show_hearing_task,
        assigned_to: organization,
        created_at: 5.days.ago
      )
    end
    let!(:no_show_hearing_task2) do
      create(:no_show_hearing_task,
             assigned_to: organization,
             created_at: 2.days.ago)
    end
    let!(:no_show_hearing_task3) do
      create(:no_show_hearing_task,
             assigned_to: organization,
             created_at: 1.day.ago)
    end

    # Even it is the oldest task, it should skip it becasue it is on hold
    let!(:no_show_hearing_task4) do
      create(:no_show_hearing_task,
             :on_hold,
             assigned_to: organization,
             created_at: 6.days.ago)
    end

    let(:assigned_to) { create(:user) }
    let(:assigned_by) { create(:user) }

    let(:params) do
      {
        assigned_to_id: assigned_to.id,
        assigned_by: assigned_by,
        organization_url: organization_url,
        task_type: task_type,
        task_count: task_count,
        regional_office: regional_office
      }
    end
    let(:task_type) { "NoShowHearingTask" }
    let(:organization_url) { organization.url }
    let(:task_count) { 2 }
    let(:regional_office) { nil }

    context "when assigned to user does not belong to organization" do
      it "does not bulk assigns tasks" do
        organization.users << assigned_by
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq false
        error = ["does not belong to organization with url #{organization.url}"]
        expect(bulk_assignment.errors[:assigned_to]).to eq error
      end
    end

    context "when regional office is not valid" do
      let(:regional_office) { "Not Valid" }

      it "does not bulk assigns tasks" do
        organization.users << assigned_to
        organization.users << assigned_by
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq false
        error = ["could not find regional office: #{regional_office}"]
        expect(bulk_assignment.errors[:regional_office]).to eq error
      end
    end

    context "when there are legacy apeals and regional office is passed" do
      let(:regional_office) { "RO17" }
      let(:legacy_appeal) { create(:legacy_appeal, closest_regional_office: regional_office) }
      let!(:no_show_hearing_task_with_legacy_appeal) do
        create(:no_show_hearing_task,
               appeal: legacy_appeal,
               assigned_to: organization,
               created_at: 2.days.ago)
      end

      it "filters by regional office" do
        no_show_hearing_task2.appeal.update(closest_regional_office: regional_office)
        no_show_hearing_task3.appeal.update(closest_regional_office: "RO19")
        organization.users << assigned_to
        organization.users << assigned_by
        count_before = Task.count
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq true
        result = bulk_assignment.process
        expect(Task.count).to eq count_before + 2
        expect(result.count).to eq 2
        task_with_ama_appeal = result.find { |task| task.appeal == no_show_hearing_task2.appeal }
        expect(task_with_ama_appeal.assigned_to).to eq assigned_to
        expect(task_with_ama_appeal.type).to eq "NoShowHearingTask"
        expect(task_with_ama_appeal.assigned_by).to eq assigned_by
        expect(task_with_ama_appeal.parent_id).to eq no_show_hearing_task2.id

        task_with_legacy_appeal = result.find { |task| task.appeal == legacy_appeal }
        expect(task_with_legacy_appeal.assigned_to).to eq assigned_to
        expect(task_with_legacy_appeal.type).to eq "NoShowHearingTask"
        expect(task_with_legacy_appeal.assigned_by).to eq assigned_by
      end
    end

    context "when task type is not valid" do
      let(:task_type) { "UnknownTaskType" }

      it "does not bulk assigns tasks" do
        organization.users << assigned_by
        organization.users << assigned_to
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq false
        error = ["#{task_type} is not a valid task type"]
        expect(bulk_assignment.errors[:task_type]).to eq error
      end
    end

    context "when organization is not valid" do
      let(:organization_url) { 1234 }

      it "does not bulk assigns tasks" do
        organization.users << assigned_by
        organization.users << assigned_to
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq false
        error = ["could not find an organization with url #{organization_url}"]
        expect(bulk_assignment.errors[:organization_url]).to eq error
      end
    end

    context "when organization cannot bulk assign" do
      let(:organization_url) { create(:organization).url }

      it "does not bulk assigns tasks" do
        organization.users << assigned_by
        organization.users << assigned_to
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq false
        error = ["with url #{organization_url} cannot bulk assign tasks"]
        expect(bulk_assignment.errors[:organization]).to eq error
      end
    end

    context "when assigned by user does not belong to organization" do
      it "does not bulk assigns tasks" do
        organization.users << assigned_to
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq false
        error = ["does not belong to organization with url #{organization.url}"]
        expect(bulk_assignment.errors[:assigned_by]).to eq error
      end
    end

    context "when all attributes are present" do
      it "bulk assigns tasks" do
        organization.users << assigned_to
        organization.users << assigned_by
        count_before = Task.count
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq true
        result = bulk_assignment.process
        expect(Task.count).to eq count_before + 2
        expect(result.count).to eq 2
        expect(result.first.assigned_to).to eq assigned_to
        expect(result.first.type).to eq "NoShowHearingTask"
        expect(result.first.assigned_by).to eq assigned_by
        expect(result.first.appeal).to eq no_show_hearing_task1.appeal
        expect(result.first.parent_id).to eq no_show_hearing_task1.id
      end
    end
  end
end
