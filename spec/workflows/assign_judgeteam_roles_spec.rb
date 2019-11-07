# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe AssignJudgeteamRoles, :postgres do
  let(:users) { create_list(:user, 4) }
  let(:judge_team) { create(:judge_team) }
  # we need to add all four users to the judge team
  # we need to make one user an admin


  fdescribe "#process" do
    subject { AssignJudgeteamRoles.new.process }
    context "when there is a JudgeTeam with an admin and several users" do
      before do
        users.each { |user| judge_team.users << user }
        OrganizationsUser.existing_record(users.first, judge_team).update!(admin: true)
      end

      it "should assign the admin user JudgeTeamLead" do
        expect(judge_team.judge_team_roles.select { |role| role.is_a?(JudgeTeamLead) }.count)
          .to eq(0)
        expect(JudgeTeamRole.count).to eq(0)
        subject
        expect(JudgeTeamRole.count).to eq(1)
        #expect(JudgeTeamRole.first.organizations_user_id).to eq(judge_team.organizations_user_ids)
        expect(OrganizationsUser.existing_record(users.first, judge_team).id)
          .to eq(JudgeTeamRole.first.organizations_user_id)

        # expect(judge_team.judge_team_roles.select { |role| role.is_a?(JudgeTeamLead) }.count)
          # .to eq(1)
#        expect(judge_team.judge_team_roles.select { |role| role.is_a?(JudgeTeamLead) }.id)
#          .to eq(1)
      end
      it "should assign the other users DecisionDraftingAttorney"
    end
  end
end
