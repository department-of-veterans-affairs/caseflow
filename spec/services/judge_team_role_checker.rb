# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe JudgeTeamRoleChecker, :postgres do

  describe ".judge_teams_with_incorrect_number_of_leads" do
    subject { JudgeTeamRoleChecker.new.judge_teams_with_incorrect_number_of_leads }

    context "when there is 1 JudgeTeam" do
      let!(:judge_teams) {[judge_team]} #{create_list(:judge_team, 1)}

      context "when team has no JudgeTeamLead" do
        let!(:judge_team) {create(:judge_team)}

        # All sub-cases should identify the team with missing JudgeTeamLead
        context "when team has no other non-JudgeTeamLead members" do
          it "identifies team with missing JudgeTeamLead" do
            expect(subject).to eq(judge_teams)
          end
        end
        context "when team has 1 other non-JudgeTeamLead members" do
        end
        context "when team has 2 other non-JudgeTeamLead members" do
        end
      end

      context "when team has 1 JudgeTeamLead" do
        let!(:judge_team) { create(:judge_team, :has_judge_team_lead) }

        # 24 is insignificant, just a moderately large number. 2 because always want at least 2 non leads.
        many_non_leads_count = rand(24) + 2
        non_lead_member_counts = [0, 1, many_non_leads_count]

        non_lead_member_counts.each do |non_lead_member_count|
          context "when team has #{non_lead_member_count} other non-JudgeTeamLead members" do
            before do
              # Add non-leads to team
              create_list(:user, non_lead_member_count) do |user|
                OrganizationsUser.add_user_to_organization(user, judge_team)
              end
            end

            it "should not report any records/errors" do
              expect(subject.empty?).to eq(true)
            end
          end
        end

        # # All sub-cases should not report any records/errors
        
        # context "when team has 1 other non-JudgeTeamLead members" do
        #   before do
        #     user = create(:user)
        #     org_user = OrganizationsUser.add_user_to_organization(user, judge_team)
        #   end
        #   it "should not report any records/errors" do
        #     expect(subject.empty?).to eq(true)
        #   end
        # end
        # context "when team has 2 other non-JudgeTeamLead members" do
        #   it "should not report any records/errors" do
        #     expect(subject.empty?).to eq(true)
        #   end
        # end
      end
    end

  end

  # Cases to check:
  # - number of JudgeTeams: 0, 1, many
  # - if team has a JudgeTeamLead: 0, 1, many
  # - if team has other members: 0, 1, many

  context "when number of JudgeTeams is 0" do
    it "returns no records/errors" do
    end
  end

  context "when there is 1 JudgeTeam" do


    context "when team has 2 JudgeTeamLead" do
      # All sub-cases should identify the team with more than 1 JudgeTeamLead
      context "when team has no other non-JudgeTeamLead members" do
      end
      context "when team has 1 other non-JudgeTeamLead members" do
      end
      context "when team has 2 other non-JudgeTeamLead members" do
      end
    end
  end

  context "when there is 2 JudgeTeam" do
    # TODO: copy from above
  end

end
