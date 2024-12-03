# frozen_string_literal: true

require "rails_helper"

RSpec.describe CorrespondenceMailTask, type: :model do
  include CorrespondenceHelpers
  include CorrespondenceTaskHelpers
  include CorrespondenceTaskActionsHelpers

  let(:assigned_user) { create(:user) }
  let(:unassigned_user) { create(:user) }

  let!(:veteran) { create(:veteran, first_name: "John", last_name: "Testingman", file_number: "8675309") }
  let!(:correspondence) { create(:correspondence, :completed, veteran: veteran) }

  describe ".verify_user_can_create!" do
    let(:inbound_ops_user) { create(:inbound_ops_team_supervisor) }

    context "When an inbound ops team user tries to create a mail task" do
      CorrespondenceTaskActionsHelpers::TASKS.each do |task_action|
        context "#{task_action[:name]} task" do
          let(:parent_task) { correspondence.root_task }

          it "allows inbound ops team users to create the task" do
            mail_task_class = task_action[:class]
            expect(mail_task_class.verify_user_can_create!(inbound_ops_user, parent_task)).to eq(true)
          end

          it "denies other users from creating the task" do
            mail_task_class = task_action[:class]
            expect { mail_task_class.verify_user_can_create!(unassigned_user, parent_task) }.to raise_error(
              Caseflow::Error::ActionForbiddenError
            )
          end
        end
      end
    end
  end

  describe "Correspondence Mail Task child classes" do
    let(:expected_actions) do
      [
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h,
        Constants.TASK_ACTIONS.COMPLETE_CORRESPONDENCE_TASK.to_h,
        Constants.TASK_ACTIONS.COR_RETURN_TO_INBOUND_OPS.to_h
      ]
    end

    # values needed for CorrespondenceTaskActionsHelpers
    let(:privacy_user) { create(:user, css_id: "PRIVACY_TEAM_USER", full_name: "Leighton PrivacyAndFOIAUser Naumov") }
    let(:cavc_user) { create(:user, css_id: "CAVC_LIT_SUPPORT_ADMIN", full_name: "CAVCLitSupportAdmin") }
    let(:liti_user) { create(:user, css_id: "LITIGATION_SUPPORT_ADMIN", full_name: "LITIGATIONSUPPORT") }
    let(:colocated_user) { create(:user, css_id: "COLOCATED_ADMIN", full_name: "ColocatedAdmin") }
    let(:hearings_user) { create(:user, css_id: "HEARINGS_ADMIN", full_name: "HearingsAdmin") }
    let(:user_team) { InboundOpsTeam.singleton }
    let(:privacy_team) { PrivacyTeam.singleton }
    let(:cavc_team) { CavcLitigationSupport.singleton }
    let(:liti_team) { LitigationSupport.singleton }
    let(:colocated_team) { Colocated.singleton }
    let(:hearings_team) { HearingAdmin.singleton }

    # iterate through each mail task
    CorrespondenceTaskActionsHelpers::TASKS.each do |task_action|
      before do
        send("correspondence_spec_#{task_action[:access_type]}")
        FeatureToggle.enable!(:correspondence_queue)
        @correspondence = create(
          :correspondence,
          :completed,
          veteran: veteran,
          va_date_of_receipt: Time.zone.now,
          nod: false,
          notes: "Notes for #{task_action[:name]}"
        )

        @task = setup_correspondence_task(
          correspondence: @correspondence,
          task_class: task_action[:class],
          assigned_to_type: task_action[:assigned_to_type],
          assigned_to: send(task_action[:assigned_to]),
          instructions: "#{task_action[:name]} Instructions",
          return_task: true
        )

        # assign user to organization
        @task.assigned_to.add_user(assigned_user)
      end

      # remove user from the organization
      after do
        OrganizationsUser.remove_user_from_organization(assigned_user, @task.assigned_to)
      end

      context ".available_actions" do
        context "for #{task_action[:name]} tasks" do
          it "#{task_action[:name]}: available actions show to the assigned user" do
            expect(@task.available_actions(assigned_user)).to eq(expected_actions)
          end

          it "#{task_action[:name]}: no actions show for unassigned users" do
            expect(@task.available_actions(unassigned_user)).to eq([])
          end
        end
      end

      context ".reassign_users" do
        let(:org_users) { create_list(:user, 10) }
        let(:organization) { @task.assigned_to }

        # add users to organization
        before do
          org_users.each do |user|
            organization.add_user(user)
          end
        end

        after do
          org_users.each do |user|
            OrganizationsUser.remove_user_from_organization(user, organization)
          end
        end

        context "The #{task_action[:name]} is assigned to an organization" do
          subject { @task.reassign_users }

          it "returns CSS IDs of all users in the organization except for the current user" do
            expect(@task.assigned_to.is_a?(Organization)).to eq(true)
            expect(subject).to eq(organization.users.reject do |user|
              user == RequestStore[:current_user]
            end.pluck(:css_id))
          end
        end

        context "The #{task_action[:name]} is assigned to a user" do
          before do
            @task.update!(assigned_to: assigned_user)
          end

          after do
            OrganizationsUser.remove_user_from_organization(assigned_user, organization)
          end

          subject { @task.reassign_users }

          it "returns the CSS IDs of users that share the same organizations" do
            # get list of adjacent org users
            adjacent_org_users = []
            assigned_user.organizations.each do |org|
              adjacent_org_users << org.users.reject { |user| user == assigned_user }.pluck(:css_id)
            end
            adjacent_org_users = adjacent_org_users.flatten

            expect(@task.assigned_to.is_a?(User)).to eq(true)
            expect(subject.include?(assigned_user.css_id)).to eq(false)
            expect(subject).to eq(adjacent_org_users)
          end
        end

        context "The #{task_action[:name]} is assigned to a user in multiple orgs" do
          let(:other_org_users) { create_list(:user, 10) }
          let(:other_organization) { @task.assigned_to }
          subject { @task.reassign_users }

          before do
            other_org_users.each do |user|
              other_organization.add_user(user)
            end

            @task.update!(assigned_to: assigned_user)
          end

          after do
            other_org_users.each do |user|
              OrganizationsUser.remove_user_from_organization(user, organization)
            end
            OrganizationsUser.remove_user_from_organization(assigned_user, organization)
          end

          it "returns the CSS IDs of users that share the same organizations" do
            # get list of adjacent org users
            adjacent_org_users = []
            assigned_user.organizations.each do |org|
              adjacent_org_users << org.users.reject { |user| user == assigned_user }.pluck(:css_id)
            end
            adjacent_org_users.flatten!

            expect(@task.assigned_to.is_a?(User)).to eq(true)
            expect(subject.include?(assigned_user.css_id)).to eq(false)
            expect(subject).to eq(adjacent_org_users.uniq)
          end
        end
      end

      context ".reassign_organizations" do
        let(:organization) { @task.assigned_to }
        subject { @task.reassign_organizations }

        context "The #{task_action[:name]} is assigned to an organization" do
          it "returns all organizations except the current assigned organization" do
            expect(subject).to eq(Organization.where.not(id: organization.id).assignable(@task))
          end
        end

        context "The #{task_action[:name]} is assigned to a user" do
          it "returns all assignable organizations" do
            expect(subject).to eq(Organization.assignable(@task))
          end
        end
      end
    end
  end
end
