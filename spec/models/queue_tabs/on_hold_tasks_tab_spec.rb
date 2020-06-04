# frozen_string_literal: true

describe OnHoldTasksTab, :postgres do
  let(:tab) { OnHoldTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee,
      show_regional_office_column: show_regional_office_column
    }
  end
  let(:assignee) { create(:user) }
  let(:show_regional_office_column) { false }

  describe ".tasks" do
    before { allow_any_instance_of(Colocated).to receive(:next_assignee).and_return(nil) }

    subject { tab.tasks }

    context "when there are tasks assigned to the assignee" do
      let!(:assignee_active_tasks) { create_list(:ama_task, 4, :assigned, assigned_to: assignee) }
      let!(:legacy_colocated_tasks) { create_list(:colocated_task, 3, :assigned, assigned_by: assignee) }
      let!(:assignee_on_hold_tasks) { create_list(:ama_task, 3, :on_hold, assigned_to: assignee) }

      it "does not return colocated tasks assigned by the user" do
        expect(subject).to match_array(assignee_on_hold_tasks)
      end

      context "when the user is a judge or attoney" do
        before { allow(assignee).to receive(:can_create_legacy_colocated_tasks?).and_return(true) }

        it "returns colocated tasks assigned by the user" do
          expect(subject).to match_array([assignee_on_hold_tasks, legacy_colocated_tasks].flatten)
        end

        context "when there are multiple tasks created for one appeal" do
          before do
            legacy_colocated_tasks.each { |task| task.update!(appeal_id: legacy_colocated_tasks.first.appeal_id) }
          end

          it "only returns one task per appeal" do
            expect(subject.count).to eq(assignee_on_hold_tasks.count + 1)
            expect(subject).to match_array([assignee_on_hold_tasks, legacy_colocated_tasks.first].flatten)
          end
        end
      end
    end

    context "when the assignee is an org" do
      let(:assignee) { create(:organization) }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end
  end
end
