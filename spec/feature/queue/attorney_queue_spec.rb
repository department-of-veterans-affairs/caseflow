# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Attorney queue" do
  describe "assigning admin actions to VLJ support staff" do
    let(:judge) { FactoryBot.create(:user) }
    let!(:vacols_judge) { FactoryBot.create(:staff, :judge_role, user: judge) }

    let(:attorney) { FactoryBot.create(:user) }
    let!(:vacols_attorney) { FactoryBot.create(:staff, :attorney_role, user: attorney) }

    let!(:judge_team) do
      JudgeTeam.create_for_judge(judge).tap { |jt| OrganizationsUser.add_user_to_organization(attorney, jt) }
    end

    let!(:colocated_team) do
      Colocated.singleton.tap { |org| OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), org) }
    end

    context "for AMA appeals" do
      let(:appeal) { FactoryBot.create(:appeal) }
      let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
      let(:judge_task) { FactoryBot.create(:ama_judge_task, appeal: appeal, assigned_to: judge, parent: root_task) }
      let(:attorney_task) do
        FactoryBot.create(
          :ama_attorney_task,
          appeal: appeal,
          assigned_by: judge,
          assigned_to: attorney,
          parent: judge_task,
          status: Constants.TASK_STATUSES.on_hold
        )
      end
      let!(:colocated_task) do
        FactoryBot.create(
          :ama_colocated_task,
          appeal: appeal,
          assigned_by: attorney,
          assigned_to: colocated_team,
          parent: attorney_task
        )
      end

      before do
        User.authenticate!(user: attorney)
      end

      it "the case only appears once in the on hold tab" do
        visit("/queue")

        expect(page).to have_content(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1))
        find("button", text: format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1)).click

        expect(find("tbody").find_all("tr").length).to eq(1)
      end
    end
  end
end
