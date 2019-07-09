# frozen_string_literal: true

require "rails_helper"
require "mail_task"

RSpec.describe Tasks::ChangeTypeController, type: :controller do
  describe "POST tasks/change_type/:id" do
    let(:user) { create(:user) }
    let(:assigner) { create(:user) }
    let(:root_task) { create(:root_task) }
    let(:old_instructions) { "Some instructions" }
    let(:new_instructions) { "New instructions" }
    let(:params) { { task: { action: new_task_type, instructions: new_instructions }, id: task.id } }

    let(:task) { parent_task.children.first }

    subject { patch(:update, params: params) }

    before do
      User.authenticate!(user: user)
      OrganizationsUser.add_user_to_organization(user, Colocated.singleton)
    end

    context "with the correct parameters" do
      context "for a colocated task" do
        let(:task_class_name) { IhpColocatedTask }
        let(:new_task_type) { Constants::CO_LOCATED_ADMIN_ACTIONS.keys.last }

        let(:parent_task) do
          task_class_name.create!(
            appeal: root_task.appeal,
            parent_id: root_task.id,
            assigned_by: assigner,
            assigned_to: Colocated.singleton,
            instructions: [old_instructions]
          )
        end

        it "should update successfully" do
          subject

          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["tasks"]["data"].sort_by { |hash| hash["id"].to_i }.reverse!
          expect(response_body.length).to eq 4
          expect(response_body.first["id"]).not_to eq task.id.to_s
          expect(response_body.first["attributes"]["label"]).to eq Constants::CO_LOCATED_ADMIN_ACTIONS[new_task_type]
          expect(response_body.first["attributes"]["status"]).to eq task.status
          expect(response_body.first["attributes"]["instructions"]).to include old_instructions
          expect(response_body.first["attributes"]["instructions"]).to include new_instructions
          expect(response_body.first["attributes"]["assigned_to"]["id"]).to eq task.assigned_to_id
          expect(response_body.first["attributes"]["assigned_by"]["pg_id"]).to eq task.assigned_by_id
          expect(response_body.first["attributes"]["appeal_id"]).to eq task.appeal_id

          new_parent_id = Task.find(response_body.first["id"]).parent_id
          new_parent = response_body.find { |t| t["id"] == new_parent_id.to_s }
          expect(new_parent["id"]).not_to eq parent_task.id.to_s
          expect(new_parent["attributes"]["label"]).to eq Constants::CO_LOCATED_ADMIN_ACTIONS[new_task_type]
          expect(new_parent["attributes"]["status"]).to eq parent_task.status
          expect(new_parent["attributes"]["instructions"]).to include old_instructions
          expect(new_parent["attributes"]["instructions"]).to include new_instructions
          expect(new_parent["attributes"]["assigned_to"]["id"]).to eq parent_task.assigned_to_id
          expect(new_parent["attributes"]["assigned_by"]["pg_id"]).to eq parent_task.assigned_by_id
          expect(new_parent["attributes"]["appeal_id"]).to eq parent_task.appeal_id

          expect(task.reload.status).to eq Constants.TASK_STATUSES.cancelled
          expect(parent_task.reload.status).to eq Constants.TASK_STATUSES.cancelled
        end
      end

      context "for a mail task" do
        let(:old_task_type) { DeathCertificateMailTask }
        let(:new_task_type) { AddressChangeMailTask }

        let(:grandparent_task) do
          old_task_type.create!(
            appeal: root_task.appeal,
            parent_id: root_task.id,
            assigned_by: assigner,
            assigned_to: MailTeam.singleton
          )
        end

        let!(:parent_task) do
          old_task_type.create!(
            appeal: grandparent_task.appeal,
            parent_id: grandparent_task.id,
            assigned_by: assigner,
            assigned_to: Colocated.singleton,
            instructions: [old_instructions]
          )
        end

        it "should update successfully" do
          subject

          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["tasks"]["data"].sort_by { |hash| hash["id"].to_i }.reverse!
          expect(response_body.length).to eq 6
          expect(response_body.first["id"]).not_to eq task.id.to_s
          expect(response_body.first["attributes"]["label"]).to eq new_task_type.label
          expect(response_body.first["attributes"]["status"]).to eq task.status
          expect(response_body.first["attributes"]["instructions"]).to include old_instructions
          expect(response_body.first["attributes"]["instructions"]).to include new_instructions
          expect(response_body.first["attributes"]["assigned_to"]["id"]).to eq task.assigned_to_id
          expect(response_body.first["attributes"]["assigned_by"]["pg_id"]).to eq task.assigned_by_id
          expect(response_body.first["attributes"]["appeal_id"]).to eq task.appeal_id

          new_parent_id = Task.find(response_body.first["id"]).parent_id
          new_parent = response_body.find { |t| t["id"] == new_parent_id.to_s }
          expect(new_parent["id"]).not_to eq parent_task.id.to_s
          expect(new_parent["attributes"]["label"]).to eq new_task_type.label
          expect(new_parent["attributes"]["status"]).to eq parent_task.status
          expect(new_parent["attributes"]["instructions"]).to include old_instructions
          expect(new_parent["attributes"]["instructions"]).to include new_instructions
          expect(new_parent["attributes"]["assigned_to"]["id"]).to eq parent_task.assigned_to_id
          expect(new_parent["attributes"]["assigned_by"]["pg_id"]).to eq parent_task.assigned_by_id
          expect(new_parent["attributes"]["appeal_id"]).to eq parent_task.appeal_id

          new_grandparent_id = Task.find(new_parent["id"]).parent_id
          new_grandparent = response_body.find { |t| t["id"] == new_grandparent_id.to_s }
          expect(new_grandparent["id"]).not_to eq grandparent_task.id.to_s
          expect(new_grandparent["attributes"]["status"]).to eq parent_task.status
          expect(new_grandparent["attributes"]["label"]).to eq new_task_type.label
          expect(new_grandparent["attributes"]["assigned_to"]["id"]).to eq grandparent_task.assigned_to_id
          expect(new_grandparent["attributes"]["assigned_by"]["pg_id"]).to eq grandparent_task.assigned_by_id
          expect(new_grandparent["attributes"]["appeal_id"]).to eq grandparent_task.appeal_id

          expect(task.reload.status).to eq Constants.TASK_STATUSES.cancelled
          expect(parent_task.reload.status).to eq Constants.TASK_STATUSES.cancelled
          expect(grandparent_task.reload.status).to eq Constants.TASK_STATUSES.cancelled
        end

        context "that needs reassigning" do
          let(:new_task_type) { CongressionalInterestMailTask }

          before do
            OrganizationsUser.add_user_to_organization(create(:user), LitigationSupport.singleton)
          end

          it "should reassign the task when changing the type" do
            subject

            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["tasks"]["data"].sort_by { |hash| hash["id"].to_i }.reverse!
            expect(response_body.length).to eq 5
            expect(response_body.first["id"]).not_to eq task.id.to_s
            expect(response_body.first["attributes"]["label"]).to eq new_task_type.label
            expect(response_body.first["attributes"]["status"]).to eq task.status
            expect(response_body.first["attributes"]["instructions"]).to include old_instructions
            expect(response_body.first["attributes"]["instructions"]).to include new_instructions
            expect(response_body.first["attributes"]["assigned_to"]["id"]).to eq LitigationSupport.singleton.id
            expect(response_body.first["attributes"]["assigned_to"]["type"]).to eq LitigationSupport.singleton.type
            expect(response_body.first["attributes"]["assigned_by"]["pg_id"]).to eq task.assigned_by_id

            new_parent_id = Task.find(response_body.first["id"]).parent_id
            new_parent = response_body.find { |t| t["id"] == new_parent_id.to_s }
            expect(new_parent["id"]).not_to eq grandparent_task.id.to_s
            expect(new_parent["attributes"]["label"]).to eq new_task_type.label
            expect(new_parent["attributes"]["assigned_to"]["id"]).to eq grandparent_task.assigned_to_id
            expect(new_parent["attributes"]["assigned_by"]["pg_id"]).to eq grandparent_task.assigned_by_id
            expect(new_parent["attributes"]["appeal_id"]).to eq grandparent_task.appeal_id

            expect(task.reload.status).to eq Constants.TASK_STATUSES.cancelled
            expect(parent_task.reload.status).to eq Constants.TASK_STATUSES.cancelled
            expect(grandparent_task.reload.status).to eq Constants.TASK_STATUSES.cancelled
          end
        end
      end
    end

    context "for a non supported task type" do
      let(:params) do
        {
          task: { action: "other", instructions: new_instructions },
          id: create(:ama_judge_task, parent: root_task).id
        }
      end

      it "returns an error" do
        subject

        expect(response.status).to eq(403)
      end
    end
  end
end
