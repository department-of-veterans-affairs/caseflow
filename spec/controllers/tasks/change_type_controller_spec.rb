# frozen_string_literal: true

require "rails_helper"
require "mail_task"

RSpec.describe Tasks::ChangeTypeController, type: :controller do
  describe "POST tasks/change_type/:id" do
    let(:user) { create(:user) }

    let(:parent) { create(:root_task) }
    let(:parent_id) { parent.id }
    let(:old_instructions) { "Some instructions" }
    let(:new_instructions) { "New instructions" }
    let(:params) { { task: { action: new_task_type, instructions: new_instructions }, id: task.id } }

    let(:task) do
      task_class_name.create!(
        appeal: parent.appeal,
        parent_id: parent.id,
        assigned_by: create(:user),
        assigned_to: user,
        action: old_task_type,
        instructions: [old_instructions]
      )
    end

    subject { patch(:update, params: params) }

    before do
      User.authenticate!(user: user)
    end

    context "with the correct parameters" do
      context "for a colocated task" do
        let(:task_class_name) { ColocatedTask }
        let(:old_task_type) { Constants::CO_LOCATED_ADMIN_ACTIONS.keys.first }
        let(:new_task_type) { Constants::CO_LOCATED_ADMIN_ACTIONS.keys.last }

        it "should update successfully" do
          subject

          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["tasks"]["data"]
          expect(response_body.first["id"]).not_to eq task.id.to_s
          expect(response_body.first["attributes"]["label"]).to eq new_task_type
          expect(response_body.first["attributes"]["instructions"]).to include old_instructions
          expect(response_body.first["attributes"]["instructions"]).to include new_instructions
          expect(response_body.first["attributes"]["assigned_to"]["id"]).to eq task.assigned_to_id
          expect(response_body.first["attributes"]["assigned_by"]["pg_id"]).to eq task.assigned_by_id
          expect(response_body.first["attributes"]["appeal_id"]).to eq task.appeal_id
          expect(Task.find(response_body.first["id"]).parent_id).to eq task.parent_id

          expect(task.reload.status).to eq Constants.TASK_STATUSES.cancelled
        end
      end

      context "for a mail task" do
        context "that doesn't need reassigning" do
          let(:task_class_name) { DeathCertificateMailTask }
          let(:old_task_type) { nil }
          let(:new_task_type) { AddressChangeMailTask }

          it "should update successfully" do
            subject

            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["tasks"]["data"]
            expect(response_body.first["id"]).not_to eq task.id.to_s
            expect(response_body.first["attributes"]["label"]).to eq new_task_type.label
            expect(response_body.first["attributes"]["instructions"]).to include old_instructions
            expect(response_body.first["attributes"]["instructions"]).to include new_instructions
            expect(response_body.first["attributes"]["assigned_to"]["id"]).to eq task.assigned_to_id
            expect(response_body.first["attributes"]["assigned_by"]["pg_id"]).to eq task.assigned_by_id
            expect(response_body.first["attributes"]["appeal_id"]).to eq task.appeal_id
            expect(Task.find(response_body.first["id"]).parent_id).to eq task.parent_id

            expect(task.reload.status).to eq Constants.TASK_STATUSES.cancelled
          end
        end
      end
    end

    context "for a non supported task type" do
      let(:params) { { task: { action: "other", instructions: new_instructions }, id: parent.id } }

      it "returns an error" do
        subject

        expect(response.status).to eq(403)
      end
    end
  end
end
