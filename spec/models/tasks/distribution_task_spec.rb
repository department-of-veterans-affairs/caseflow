# frozen_string_literal: true

describe DistributionTask, :postgres do
  let(:user) { create(:user) }
  let(:scm_user) { create(:user) }
  let(:scm_org) { SpecialCaseMovementTeam.singleton }
  let(:root_task) { create(:root_task) }
  let(:distribution_task) do
    DistributionTask.create!(
      appeal: root_task.appeal,
      assigned_to: Bva.singleton
    )
  end

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

  describe "after_update hooks" do
    before do
      distribution_task.update!(status: "on_hold")
      create(:appeal_affinity, appeal: distribution_task.appeal)
    end

    context "when affinity appeal is not set to assigned" do
      it "returns an affinity appeal start date with no instructions" do
        expect(distribution_task.appeal.appeal_affinity.affinity_start_date).to_not eq nil
        expect(distribution_task.instructions.size).to eq 0
      end
    end

    context "when affinity appeal is set to assigned" do
      before { distribution_task.ready_for_distribution! }

      it "returns no affinity appeal start date with instructions" do
        expect(distribution_task.appeal.appeal_affinity.affinity_start_date).to eq nil
        expect(distribution_task.instructions.size).to eq 1
      end
    end

    context "when no affinity appeal is linked" do
      let(:root_task_without_affinity) { create(:root_task) }
      let(:distribution_task_without_affinity) do
        DistributionTask.create!(
          appeal: root_task_without_affinity.appeal,
          assigned_to: Bva.singleton
        )
      end

      before do
        distribution_task_without_affinity.update!(status: "on_hold")
        distribution_task_without_affinity.ready_for_distribution!
      end

      it "should be assigned" do
        expect(distribution_task_without_affinity.status).to eq "assigned"
      end

      it "returns no affinity appeal record" do
        expect(distribution_task_without_affinity.appeal.appeal_affinity).to eq nil
      end

      it "does not update instructions" do
        expect(distribution_task_without_affinity.instructions.size).to eq 0
      end
    end
  end
end
