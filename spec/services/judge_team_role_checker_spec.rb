# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe JudgeTeamRoleChecker, :postgres do
  get_teams_with_wrong_lead_count = JudgeTeamRoleChecker.method(:judge_teams_with_incorrect_number_of_leads)
  get_teams_with_nonadmin_leads = JudgeTeamRoleChecker.method(:non_admin_judge_team_leads)

  # Variables in cases to check:
  # - number of JudgeTeams: 0, 1, many
  # - if team has a JudgeTeamLead: 0, 1, many
  # - if team has other members: 0, 1, many

  context "when there is no JudgeTeam" do
    describe ".judge_teams_with_incorrect_number_of_leads" do
      it "returns no records/errors" do
        expect(get_teams_with_wrong_lead_count.call).to be_empty
      end
    end
    describe ".non_admin_judge_team_leads" do
      it "returns no records/errors" do
        expect(get_teams_with_nonadmin_leads.call).to be_empty
      end
    end
    it "reports no error" do
      subject.call
      expect(subject.report?).to eq(false)
    end
  end

  # 24 is insignificant, just a moderately large number. 2 because always want at least 2 non-leads.
  many_non_leads_count = rand(2..24)
  non_lead_member_counts = [0, 1, many_non_leads_count]

  context "when there is 1 JudgeTeam" do
    let!(:judge_teams) { [judge_team] }

    context "when team has no JudgeTeamLead" do
      # All sub-cases should identify the team with missing JudgeTeamLead
      let!(:judge_team) { create(:judge_team) }

      non_lead_member_counts.each do |non_lead_member_count|
        context "when team has #{non_lead_member_count} other non-JudgeTeamLead members" do
          before do
            # Add non-leads to team
            create_list(:user, non_lead_member_count) do |user|
              OrganizationsUser.add_user_to_organization(user, judge_team)
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "identifies team with missing JudgeTeamLead" do
              expect(get_teams_with_wrong_lead_count.call).to eq(judge_teams)
            end
          end

          describe ".non_admin_judge_team_leads" do
            it "does not report any records/errors" do
              expect(get_teams_with_nonadmin_leads.call).to be_empty
            end
          end

          it "reports JudgeTeamLeads count error" do
            subject.call
            expect(subject.report?).to eq(true)
            expect(subject.report).to match(/has the incorrect number of associated JudgeTeamLeads/)
          end
        end
      end
    end

    context "when team has 1 JudgeTeamLead and not an admin" do
      # All sub-cases should not report any error
      let!(:judge_team) { create(:judge_team, :has_judge_team_lead) }
      let(:judge_team_leads) { judge_team.judge_team_roles.where(type: :JudgeTeamLead).to_a }

      non_lead_member_counts.each do |non_lead_member_count|
        context "when team has #{non_lead_member_count} other non-JudgeTeamLead members" do
          before do
            # Add non-leads to team
            create_list(:user, non_lead_member_count) do |user|
              OrganizationsUser.add_user_to_organization(user, judge_team)
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "does not report any records/errors" do
              expect(get_teams_with_wrong_lead_count.call).to be_empty
            end
          end

          describe ".non_admin_judge_team_leads" do
            it "identifies JudgeTeamLeads who are not admins" do
              expect(get_teams_with_nonadmin_leads.call).to eq(judge_team_leads)
            end
          end

          it "reports 'not an admin' error" do
            subject.call
            expect(subject.report?).to eq(true)
            expect(subject.report).to match(/is not an admin/)
          end
        end
      end
    end

    context "when team has 1 JudgeTeamLead and is an admin" do
      # All sub-cases should not report any error
      let!(:judge_team) { create(:judge_team, :has_judge_team_lead_as_admin) }

      non_lead_member_counts.each do |non_lead_member_count|
        context "when team has #{non_lead_member_count} other non-JudgeTeamLead members" do
          before do
            # Add non-leads to team
            create_list(:user, non_lead_member_count) do |user|
              OrganizationsUser.add_user_to_organization(user, judge_team)
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "does not report any records/errors" do
              expect(get_teams_with_wrong_lead_count.call).to be_empty
            end
          end

          describe ".non_admin_judge_team_leads" do
            it "does not report any records/errors" do
              expect(get_teams_with_nonadmin_leads.call).to be_empty
            end
          end

          it "reports no error" do
            subject.call
            expect(subject.report?).to eq(false)
          end
        end
      end
    end

    context "when there are 2 JudgeTeamLeads and not an admin" do
      # All sub-cases should identify the team with missing JudgeTeamLead
      let!(:judge_team) { create(:judge_team, :has_two_judge_team_lead) }
      let(:judge_team_leads) { judge_team.judge_team_roles.where(type: :JudgeTeamLead).to_a }

      non_lead_member_counts.each do |non_lead_member_count|
        context "when team has #{non_lead_member_count} other non-JudgeTeamLead members" do
          before do
            # Add non-leads to team
            create_list(:user, non_lead_member_count) do |user|
              OrganizationsUser.add_user_to_organization(user, judge_team)
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "identifies teams with 2 JudgeTeamLeads" do
              expect(get_teams_with_wrong_lead_count.call).to eq(judge_teams)
            end
          end

          describe ".non_admin_judge_team_leads" do
            it "identifies teams with 2 JudgeTeamLead but no admin" do
              expect(get_teams_with_nonadmin_leads.call).to eq(judge_team_leads)
            end
          end

          it "reports both errors" do
            subject.call
            expect(subject.report?).to eq(true)
            expect(subject.report).to match(/has the incorrect number of associated JudgeTeamLeads/)
            expect(subject.report).to match(/is not an admin/)
          end
        end
      end
    end

    context "when there are 2 JudgeTeamLeads and is an admin" do
      # All sub-cases should identify the team with missing JudgeTeamLead
      let!(:judge_team) { create(:judge_team, :has_two_judge_team_lead_as_admins) }

      non_lead_member_counts.each do |non_lead_member_count|
        context "when team has #{non_lead_member_count} other non-JudgeTeamLead members" do
          before do
            # Add non-leads to team
            create_list(:user, non_lead_member_count) do |user|
              OrganizationsUser.add_user_to_organization(user, judge_team)
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "identifies teams with 2 JudgeTeamLeads" do
              expect(get_teams_with_wrong_lead_count.call).to eq(judge_teams)
            end
          end

          describe ".non_admin_judge_team_leads" do
            it "identifies 2 JudgeTeamLeads who are not admins" do
              expect(get_teams_with_nonadmin_leads.call).to be_empty
            end
          end

          it "reports JudgeTeamLeads count error" do
            subject.call
            expect(subject.report?).to eq(true)
            expect(subject.report).to match(/has the incorrect number of associated JudgeTeamLeads/)
          end
        end
      end
    end
  end

  context "when there are 2 JudgeTeams" do
    let!(:judge_teams) { [judge_team1, judge_team2] }

    context "when all teams have no JudgeTeamLead" do
      # All sub-cases should identify the team with missing JudgeTeamLead
      let!(:judge_team1) { create(:judge_team) }
      let!(:judge_team2) { create(:judge_team) }

      non_lead_member_counts.each do |non_lead_member_count|
        context "when team2 has #{non_lead_member_count} other non-JudgeTeamLead members" do
          before do
            # Add non-leads to team
            create_list(:user, non_lead_member_count) do |user|
              OrganizationsUser.add_user_to_organization(user, judge_team2)
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "identifies team with missing JudgeTeamLead" do
              expect(get_teams_with_wrong_lead_count.call).to eq(judge_teams)
            end
          end

          describe ".non_admin_judge_team_leads" do
            it "does not report any records/errors" do
              expect(get_teams_with_nonadmin_leads.call).to be_empty
            end
          end

          it "reports JudgeTeamLeads count error" do
            subject.call
            expect(subject.report?).to eq(true)
            expect(subject.report).to match(/has the incorrect number of associated JudgeTeamLeads/)
          end
        end
      end
    end

    context "when only team1 has 1 JudgeTeamLead and not an admin" do
      let!(:judge_team1) { create(:judge_team, :has_judge_team_lead) }
      let(:judge_team_leads1) { judge_team1.judge_team_roles.where(type: :JudgeTeamLead).to_a }
      let!(:judge_team2) { create(:judge_team) }

      non_lead_member_counts.each do |non_lead_member_count|
        context "when team2 has #{non_lead_member_count} other non-JudgeTeamLead members" do
          before do
            # Add non-leads to team
            create_list(:user, non_lead_member_count) do |user|
              OrganizationsUser.add_user_to_organization(user, judge_team2)
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "identifies the team with missing JudgeTeamLead" do
              expect(get_teams_with_wrong_lead_count.call).to eq([judge_team2])
            end
          end

          describe ".non_admin_judge_team_leads" do
            it "identifies JudgeTeamLeads who are not admins" do
              expect(get_teams_with_nonadmin_leads.call).to eq(judge_team_leads1)
            end
          end

          it "reports both errors" do
            subject.call
            expect(subject.report?).to eq(true)
            expect(subject.report).to match(/has the incorrect number of associated JudgeTeamLeads/)
            expect(subject.report).to match(/is not an admin/)
          end
        end
      end
    end

    context "when only team1 has 1 JudgeTeamLead and is an admin" do
      let!(:judge_team1) { create(:judge_team, :has_judge_team_lead_as_admin) }
      let!(:judge_team2) { create(:judge_team) }

      non_lead_member_counts.each do |non_lead_member_count|
        context "when team2 has #{non_lead_member_count} other non-JudgeTeamLead members" do
          before do
            # Add non-leads to team
            create_list(:user, non_lead_member_count) do |user|
              OrganizationsUser.add_user_to_organization(user, judge_team2)
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "identifies the team with missing JudgeTeamLead" do
              expect(get_teams_with_wrong_lead_count.call).to eq([judge_team2])
            end
          end

          describe ".non_admin_judge_team_leads" do
            it "does not report any records/errors" do
              expect(get_teams_with_nonadmin_leads.call).to be_empty
            end
          end

          it "reports JudgeTeamLeads count error" do
            subject.call
            expect(subject.report?).to eq(true)
            expect(subject.report).to match(/has the incorrect number of associated JudgeTeamLeads/)
          end
        end
      end
    end

    context "when one team has 2 non-admin JudgeTeamLeads and other team has none" do
      let!(:judge_team1) { create(:judge_team, :has_two_judge_team_lead) }
      let(:judge_team_leads1) { judge_team1.judge_team_roles.where(type: :JudgeTeamLead).to_a }
      let!(:judge_team2) { create(:judge_team) }

      non_lead_member_counts.each do |non_lead_member_count|
        context "when team2 has #{non_lead_member_count} other non-JudgeTeamLead members" do
          before do
            # Add non-leads to team
            create_list(:user, non_lead_member_count) do |user|
              OrganizationsUser.add_user_to_organization(user, judge_team2)
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "identifies both teams as problematic" do
              expect(get_teams_with_wrong_lead_count.call).to eq(judge_teams)
            end
          end

          describe ".non_admin_judge_team_leads" do
            it "identifies JudgeTeamLeads who are not admins" do
              expect(get_teams_with_nonadmin_leads.call).to eq(judge_team_leads1)
            end
          end

          it "reports both errors" do
            subject.call
            expect(subject.report?).to eq(true)
            expect(subject.report).to match(/has the incorrect number of associated JudgeTeamLeads/)
            expect(subject.report).to match(/is not an admin/)
          end
        end
      end
    end

    context "when one team has 2 admin JudgeTeamLeads and other team has none" do
      let!(:judge_team1) { create(:judge_team, :has_two_judge_team_lead_as_admins) }
      let!(:judge_team2) { create(:judge_team) }

      non_lead_member_counts.each do |non_lead_member_count|
        context "when team2 has #{non_lead_member_count} other non-JudgeTeamLead members" do
          before do
            # Add non-leads to team
            create_list(:user, non_lead_member_count) do |user|
              OrganizationsUser.add_user_to_organization(user, judge_team2)
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "identifies both teams as problematic" do
              expect(get_teams_with_wrong_lead_count.call).to eq(judge_teams)
            end
          end

          describe ".non_admin_judge_team_leads" do
            it "returns no records/errors" do
              expect(get_teams_with_nonadmin_leads.call).to be_empty
            end
          end

          it "reports JudgeTeamLeads count error" do
            subject.call
            expect(subject.report?).to eq(true)
            expect(subject.report).to match(/has the incorrect number of associated JudgeTeamLeads/)
          end
        end
      end
    end
  end
end
