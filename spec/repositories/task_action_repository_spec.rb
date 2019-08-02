# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe TaskActionRepository, :all_dbs do
  describe "#assign_to_user_data" do
    let(:organization) { create(:organization, name: "Organization") }
    let(:users) { create_list(:user, 3) }

    before do
      allow(organization).to receive(:users).and_return(users)
    end

    context "when assigned_to is an organization" do
      let(:task) { create(:generic_task, assigned_to: organization) }

      it "should return all members" do
        match_users = users.map { |u| { label: u.full_name, value: u.id } }
        expect(TaskActionRepository.assign_to_user_data(task)[:options]).to match_array match_users
      end

      it "should return the task type of task" do
        expect(TaskActionRepository.assign_to_user_data(task)[:type]).to eq(task.type)
      end
    end

    context "when assigned_to's parent is an organization" do
      let(:parent) { create(:generic_task, assigned_to: organization) }
      let(:task) { create(:generic_task, assigned_to: users.first, parent: parent) }

      it "should return all members except user" do
        user_output = users[1..users.length - 1].map { |u| { label: u.full_name, value: u.id } }
        expect(TaskActionRepository.assign_to_user_data(task)[:options]).to match_array(user_output)
      end
    end

    context "when assigned_to is a user" do
      let(:task) { create(:generic_task, assigned_to: users.first) }

      it "should return all members except user" do
        expect(TaskActionRepository.assign_to_user_data(task)[:options]).to match_array([])
      end
    end
  end

  describe "#return_to_attorney_data" do
    let(:attorney) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Janet Avilez") }
    let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
    let(:judge) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge") }
    let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }
    let!(:judge_team) { JudgeTeam.create_for_judge(judge) }
    let(:judge_task) { create(:ama_judge_decision_review_task, assigned_to: judge) }
    let!(:attorney_task) do
      create(:ama_attorney_task, assigned_to: attorney, parent: judge_task, appeal: judge_task.appeal)
    end

    subject { TaskActionRepository.return_to_attorney_data(judge_task) }

    context "there aren't any attorneys on the JudgeTeam" do
      it "still shows the assigned attorney in selected and options" do
        expect(subject[:selected]).to eq attorney
        expect(subject[:options]).to eq [{ label: attorney.full_name, value: attorney.id }]
      end
    end

    context "there are attorneys on the JudgeTeam" do
      let(:attorney_names) { ["Jesse Abrecht", "Brenda Akery", "Crystal Andregg"] }

      before do
        OrganizationsUser.add_user_to_organization(attorney, judge_team)

        attorney_names.each do |attorney_name|
          another_attorney_on_the_team = create(
            :user, station_id: User::BOARD_STATION_ID, full_name: attorney_name
          )
          create(:staff, :attorney_role, user: another_attorney_on_the_team)
          OrganizationsUser.add_user_to_organization(another_attorney_on_the_team, judge_team)
        end
      end

      it "shows the assigned attorney in selected, and all attorneys in options" do
        expect(subject[:selected]).to eq attorney
        expect(judge_team.non_admins.count).to eq attorney_names.count + 1
        judge_team.non_admins.each do |team_attorney|
          expect(subject[:options]).to include(label: team_attorney.full_name, value: team_attorney.id)
        end
      end
    end
  end

  describe "#cancel_task_data" do
    let(:task) { create(:generic_task, assigned_by_id: assigner_id) }
    subject { TaskActionRepository.cancel_task_data(task) }

    context "when the task has no assigner" do
      let(:assigner_id) { nil }
      it "fills in the assigner name with placeholder text" do
        expect(subject[:message_detail]).to eq(format(COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, "the assigner"))
      end
    end
  end
end
