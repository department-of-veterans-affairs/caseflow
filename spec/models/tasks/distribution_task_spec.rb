# frozen_string_literal: true

describe DistributionTask, :postgres do
  describe "ready_for_distribution" do
    before do
      Timecop.freeze(Time.zone.today)
    end

    after do
      Timecop.return
    end

    let(:distribution_task) do
      create(
        :distribution_task,
        appeal: create(:appeal),
        assigned_to: Bva.singleton
      )
    end

    it "is set to assigned and ready for distribution is tracked when all child tasks are completed" do
      child_task = create(:informal_hearing_presentation_task, parent: distribution_task)
      expect(distribution_task.ready_for_distribution?).to eq(false)

      child_task.update!(status: "completed")
      expect(distribution_task.ready_for_distribution?).to eq(true)
      expect(distribution_task.ready_for_distribution_at).to eq(Time.zone.now)

      another_child_task = create(:informal_hearing_presentation_task, parent: distribution_task)
      expect(distribution_task.ready_for_distribution?).to eq(false)

      Timecop.freeze(Time.zone.now + 1.day)

      another_child_task.update!(status: "completed")
      expect(distribution_task.ready_for_distribution?).to eq(true)
      expect(distribution_task.ready_for_distribution_at).to eq(Time.zone.now)
    end
  end

  describe ".available_actions" do
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
end
