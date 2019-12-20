# frozen_string_literal: true

describe JudgeTeamRoleChecker, :postgres do
  get_teams_with_wrong_lead_count = JudgeTeamRoleChecker.method(:judge_teams_with_incorrect_number_of_leads)
  get_teams_with_nonadmin_leads = JudgeTeamRoleChecker.method(:non_admin_judge_team_leads)

  # Variables in cases to check:
  # - number of JudgeTeams: 0, many (where 1 team varies in problematic scenarios)
  # - if team has a JudgeTeamLead: 0, 1
  #   (cannot have more than 1 lead per organizations_user due to uniqueness constraint in schema)
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
    describe "when checker instance is called" do
      it "reports no error" do
        subject.call
        expect(subject.report?).to eq(false)
      end
    end
  end

  # testing up to 12 because it is 30% larger than our normal
  many_non_leads_count = rand(2..12)
  non_lead_member_counts = [0, 1, many_non_leads_count]

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
              # Do not call judge_team.add_user b/c that sets first team member as lead
              judge_team2.users << user
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "identifies team with missing JudgeTeamLead" do
              expect(get_teams_with_wrong_lead_count.call).to match_array(judge_teams)
            end
          end

          describe ".non_admin_judge_team_leads" do
            it "does not report any records/errors" do
              expect(get_teams_with_nonadmin_leads.call).to be_empty
            end
          end

          describe "when checker instance is called" do
            it "reports JudgeTeamLeads count error" do
              subject.call
              expect(subject.report?).to eq(true)
              expect(subject.report).to match(/has the incorrect number of associated JudgeTeamLeads/)
            end
          end
        end
      end
    end

    context "when only team1 has 1 JudgeTeamLead and not an admin" do
      let!(:judge_team1) { create(:judge_team, :incorrectly_has_nonadmin_judge_team_lead) }
      let(:judge_team_leads1) { judge_team1.judge_team_roles.where(type: :JudgeTeamLead) }
      let!(:judge_team2) { create(:judge_team) }

      non_lead_member_counts.each do |non_lead_member_count|
        context "when team2 has #{non_lead_member_count} other non-JudgeTeamLead members" do
          before do
            # Add non-leads to team
            create_list(:user, non_lead_member_count) do |user|
              # Do not call judge_team.add_user b/c that sets first team member as lead
              judge_team2.users << user
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "identifies the team with missing JudgeTeamLead" do
              expect(get_teams_with_wrong_lead_count.call).to contain_exactly(judge_team2)
            end
          end

          describe ".non_admin_judge_team_leads" do
            it "identifies JudgeTeamLeads who are not admins" do
              expect(get_teams_with_nonadmin_leads.call).to match_array(judge_team_leads1)
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
              # Do not call judge_team.add_user b/c that sets first team member as lead
              judge_team2.users << user
            end
          end

          describe ".judge_teams_with_incorrect_number_of_leads" do
            it "identifies the team with missing JudgeTeamLead" do
              expect(get_teams_with_wrong_lead_count.call).to contain_exactly(judge_team2)
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
  end
end
