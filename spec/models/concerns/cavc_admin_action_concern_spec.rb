# frozen_string_literal: true

describe CavcAdminActionConcern do
  class TestTask < Task
    include CavcAdminActionConcern
  end

  let(:parent_task) { create(:distribution_task) }
  let(:user) { create(:user).tap { |new_user| CavcLitigationSupport.singleton.add_user(new_user) } }
  let!(:cavc_task) { create(:send_cavc_remand_processed_letter_task, assigned_to: user, appeal: parent_task.appeal) }

  describe ".creating_from_cavc_workflow?" do
    subject { TestTask.creating_from_cavc_workflow?(user, parent_task) }

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
end
