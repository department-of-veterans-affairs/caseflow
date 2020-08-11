# frozen_string_literal: true

describe DistributionTask, :postgres do
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
    end

    it "with a child task it has no actions" do
      CongressionalInterestMailTask.create_from_params({
                                                         appeal: distribution_task.appeal,
                                                         parent_id: distribution_task.appeal.root_task.id
                                                       }, user)
      expect(distribution_task.available_actions(scm_user).count).to eq(0)
    end
  end
end
