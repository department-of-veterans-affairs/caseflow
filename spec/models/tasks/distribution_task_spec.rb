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

  describe "validations" do
    before do
      distribution_task.update!(status: "completed")
    end

    context "when there are open JudgeAssignTasks" do
      let!(:judge_assign_task) do
        judge_assign_task = JudgeAssignTask.create!(
          appeal: distribution_task.appeal,
          parent_id: distribution_task.appeal.root_task.id,
          assigned_to: create(:field_vso),
          status: "assigned"
        )

        judge_assign_task.update!(status: "in_progress")
      end

      it "prevents changing the status from 'completed' to an active status" do
        distribution_task.status = "assigned"
        puts "Is distribution_task valid? #{distribution_task.valid?}"
        expect(distribution_task.valid?).to be false
        expect(distribution_task.errors[distribution_task.status]).to include("cannot be changed from this status if there are open JudgeAssignTasks")
      end
    end

    # completed -> on_hold -> assigned
    # completed -> assigned
    # completed -> in_progress
    # if status ever was completed, block change to active
    #
    # completed -> on_hold -> assigned -> on_hold -> assigned -> on_hold -> completed - Creates two JudgeAssignTasks

    context "when there are no open JudgeAssignTasks" do
      it "allows changing the status from 'completed' to an active status" do
        distribution_task.status = "assigned"
        expect(distribution_task.valid?).to be true
      end
    end
  end
end
