# frozen_string_literal: true

describe CavcAdminActionConcern do
  class TestTask < Task
    include CavcAdminActionConcern
  end

  let(:parent_task) { create(:distribution_task) }
  let(:cavc_user) { create(:user).tap { |new_user| CavcLitigationSupport.singleton.add_user(new_user) } }
  let!(:cavc_task) do
    create(:send_cavc_remand_processed_letter_task, assigned_to: cavc_user, appeal: parent_task.appeal)
  end

  describe ".creating_from_cavc_workflow?" do
    subject { TestTask.creating_from_cavc_workflow?(cavc_user, parent_task) }

    it { is_expected.to be true }

    context "when the parent task is not a distribution task" do
      before { parent_task.update!(type: "NotDistribution") }

      it { is_expected.to be false }
    end

    context "when there is no cavc task on the appeal" do
      before { cavc_task.update!(appeal: create(:appeal)) }

      it { is_expected.to be false }
    end

    context "when the user does not have an assigned cavc task" do
      before { cavc_task.update!(assigned_to: create(:user)) }

      it { is_expected.to be false }
    end
  end

  describe "#verify_org_task_uniq" do
    context "ScheduleHearingTask" do
      let(:assigner) { cavc_user }

      subject { ScheduleHearingTask.create!(assigned_by: assigner, appeal: parent_task.appeal, parent: parent_task) }

      before { ScheduleHearingTask.create!(assigned_by: assigner, appeal: parent_task.appeal, parent: parent_task) }

      context "when creating from a cavc workflow" do
        it "fails validation" do
          expect { subject }.to raise_error(Caseflow::Error::DuplicateOrgTask)
        end
      end

      context "when creating from a non cavc workflow" do
        let(:assigner) { create(:user) }

        it "does not fail validation" do
          expect { subject }.to_not raise_error
        end
      end
    end
  end
end
