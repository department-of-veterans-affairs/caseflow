# frozen_string_literal: true

describe DistributionTask, :postgres do
  let(:user) { create(:user) }
  let(:scm_user) { create(:user) }
  let(:scm_org) { SpecialCaseMovementTeam.singleton }
  let(:root_task) { create(:root_task) }
  let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks) }
  let(:root_task_legacy) { create(:root_task, :legacy_appeal) }
  let(:distribution_task) do
    DistributionTask.create!(
      appeal: root_task.appeal,
      assigned_to: Bva.singleton
    )
  end
  let(:distribution_task_legacy) do
    DistributionTask.create!(
      appeal: root_task_legacy.appeal,
      assigned_to: Bva.singleton
    )
  end

  let(:distribution_task_legacy) { legacy_appeal.tasks.find { |task| task.type == "DistributionTask" } }

  before do
    MailTeam.singleton.add_user(user)
    scm_org.add_user(scm_user)
  end

  describe ".available_actions" do
    it "with regular user has no actions" do
      expect(distribution_task.available_actions(user).count).to eq(0)
    end

    it "with Case Movement Team user has the Case Movement action" do
      expect(distribution_task.available_actions(scm_user).count).to eq(1)
      expect(distribution_task.available_actions(scm_user).first).to eq(
        Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT.to_h
      )
    end

    it "with congressional interest mail task it has no actions" do
      CongressionalInterestMailTask.create_from_params({
                                                         appeal: distribution_task.appeal,
                                                         parent_id: distribution_task.appeal.root_task.id
                                                       }, user)
      expect(distribution_task.available_actions(scm_user).count).to eq(0)
    end

    it "with address change mail task it has actions" do
      AodMotionMailTask.create!(
        appeal: distribution_task.appeal,
        parent_id: distribution_task.appeal.root_task.id,
        assigned_to: MailTeam.singleton
      )
      expect(distribution_task.available_actions(scm_user).count).to eq(1)
    end

    context "with scm blocking tasks enabled" do
      before { FeatureToggle.enable!(:scm_move_with_blocking_tasks, users: [scm_user.css_id]) }
      after { FeatureToggle.disable!(:scm_move_with_blocking_tasks) }

      it "with congressional interest mail task it has a blocking case movement action" do
        CongressionalInterestMailTask.create_from_params({
                                                           appeal: distribution_task.appeal,
                                                           parent_id: distribution_task.appeal.root_task.id
                                                         }, user)
        expect(distribution_task.available_actions(scm_user).count).to eq(1)
        expect(distribution_task.available_actions(scm_user).first).to eq(
          Constants.TASK_ACTIONS.BLOCKED_SPECIAL_CASE_MOVEMENT.to_h
        )
      end
    end

    it "with legacy case" do
      expect(distribution_task.available_actions(scm_user).count).to eq(1)
    end
  end

  describe ".actions_available?" do
    context "when the user is not a member of the case movement team" do
      it "returns false" do
        expect(distribution_task.actions_available?(user)).to be false
      end
    end

    context "when the user is a member of the case movement team" do
      it "returns true" do
        expect(distribution_task.actions_available?(scm_user)).to be true
      end
    end
  end
end
