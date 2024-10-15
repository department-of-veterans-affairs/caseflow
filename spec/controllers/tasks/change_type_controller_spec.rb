# frozen_string_literal: true

RSpec.describe Tasks::ChangeTypeController, :postgres, type: :controller do
  describe "POST tasks/change_type/:id" do
    let(:user) { create(:user) }
    let(:assigner) { create(:user) }
    let(:root_task) { create(:root_task) }
    let(:old_instructions) { "Some instructions" }
    let(:new_instructions) { "New instructions" }
    let(:params) { { task: { type: new_task_type, instructions: new_instructions }, id: task.id } }

    let(:task) { parent_task.children.first }

    subject { patch(:update, params: params) }

    before do
      User.authenticate!(user: user)
      Colocated.singleton.add_user(user)
    end

    context "with the correct parameters" do
      context "for a colocated task" do
        let(:old_task_type_trait) { :ihp }
        let(:new_task_type) { OtherColocatedTask }

        let(:parent_task) do
          create(
            :ama_colocated_task,
            old_task_type_trait,
            appeal: root_task.appeal,
            parent_id: root_task.id,
            assigned_by: assigner,
            instructions: [old_instructions]
          )
        end

        let!(:child_task) do
          create(
            :ama_colocated_task,
            old_task_type_trait,
            appeal: parent_task.appeal,
            parent: parent_task,
            instructions: [old_instructions],
            assigned_by: assigner,
            assigned_to: create(:user, :vlj_support_user)
          )
        end

        it "should update successfully" do
          subject

          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["tasks"]["data"].sort_by { |hash| hash["id"].to_i }.reverse!
          expect(response_body.length).to eq 3

          new_parent_id = response_body.first["id"]
          new_parent = response_body.find { |t| t["id"] == new_parent_id.to_s }
          expect(new_parent["id"]).not_to eq parent_task.id.to_s
          expect(new_parent["attributes"]["label"]).to eq new_task_type.label
          expect(new_parent["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
          expect(new_parent["attributes"]["instructions"]).to include old_instructions
          expect(new_parent["attributes"]["instructions"]).to include new_instructions
          expect(new_parent["attributes"]["assigned_to"]["id"]).to eq parent_task.assigned_to_id
          expect(new_parent["attributes"]["assigned_by"]["pg_id"]).to eq parent_task.assigned_by_id
          expect(new_parent["attributes"]["appeal_id"]).to eq parent_task.appeal_id

          expect(task.reload.status).to eq Constants.TASK_STATUSES.cancelled
          expect(parent_task.reload.status).to eq Constants.TASK_STATUSES.cancelled
        end

        context "that needs reassigning" do
          let(:new_task_type) { FoiaColocatedTask }

          it "should update successfully" do
            subject

            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["tasks"]["data"].sort_by { |hash| hash["id"].to_i }.reverse!
            expect(response_body.length).to eq 4
            expect(response_body.first["id"]).not_to eq task.id.to_s
            expect(response_body.first["attributes"]["label"]).to eq FoiaTask.name.titlecase
            expect(response_body.first["attributes"]["status"]).to eq task.status
            expect(response_body.first["attributes"]["instructions"]).to include old_instructions
            expect(response_body.first["attributes"]["instructions"]).to include new_instructions
            expect(response_body.first["attributes"]["type"]).to eq FoiaTask.name
            expect(response_body.first["attributes"]["assigned_to"]["id"]).to eq FoiaColocatedTask.default_assignee.id
            expect(response_body.first["attributes"]["assigned_by"]["pg_id"]).to eq task.assigned_by_id
            expect(response_body.first["attributes"]["appeal_id"]).to eq task.appeal_id

            new_parent_id = Task.find(response_body.first["id"]).parent_id
            new_parent = response_body.find { |t| t["id"] == new_parent_id.to_s }
            expect(new_parent["id"]).not_to eq parent_task.id.to_s
            expect(new_parent["attributes"]["label"]).to eq new_task_type.label
            expect(new_parent["attributes"]["status"]).to eq parent_task.status
            expect(new_parent["attributes"]["instructions"]).to include old_instructions
            expect(new_parent["attributes"]["instructions"]).to include new_instructions
            expect(new_parent["attributes"]["type"]).to eq FoiaColocatedTask.name
            expect(new_parent["attributes"]["assigned_to"]["id"]).to eq FoiaColocatedTask.default_assignee.id
            expect(new_parent["attributes"]["assigned_by"]["pg_id"]).to eq parent_task.assigned_by_id
            expect(new_parent["attributes"]["appeal_id"]).to eq parent_task.appeal_id

            expect(task.reload.status).to eq Constants.TASK_STATUSES.cancelled
            expect(parent_task.reload.status).to eq Constants.TASK_STATUSES.cancelled
          end
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

        let!(:user_task) do
          old_task_type.create!(
            appeal: parent_task.appeal,
            parent_id: parent_task.id,
            assigned_to: create(:user),
            assigned_by: assigner,
            instructions: [old_instructions]
          )
        end

        it "should update successfully" do
          subject

          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["tasks"]["data"].sort_by { |hash| hash["id"].to_i }.reverse!

          # This is the parent of the task we started, because Colocated tasks do not auto-assign user tasks.
          expect(response_body.length).to eq 5
          expect(response_body.first["id"]).not_to eq task.id.to_s
          expect(response_body.first["attributes"]["label"]).to eq new_task_type.label
          expect(response_body.first["attributes"]["status"]).to eq task.status
          expect(response_body.first["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
          expect(response_body.first["attributes"]["instructions"]).to include old_instructions
          expect(response_body.first["attributes"]["instructions"]).to include new_instructions
          expect(response_body.first["attributes"]["assigned_to"]["id"]).to eq parent_task.assigned_to_id
          expect(response_body.first["attributes"]["assigned_by"]["pg_id"]).to eq parent_task.assigned_by_id
          expect(response_body.first["attributes"]["appeal_id"]).to eq task.appeal_id

          # This refers to the organization task of the same type, but assigned to the Mail Team:
          new_grandparent_id = Task.find(response_body.first["id"]).parent_id
          new_grandparent = response_body.find { |t| t["id"] == new_grandparent_id.to_s }
          expect(new_grandparent["id"]).not_to eq grandparent_task.id.to_s
          expect(new_grandparent["attributes"]["status"]).to eq Constants.TASK_STATUSES.on_hold
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
            LitigationSupport.singleton.add_user(create(:user))
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
      let(:new_task_type) { PreRoutingFoiaColocatedTask }
      let(:parent_task) do
        create(
          :ama_colocated_task,
          :ihp,
          appeal: root_task.appeal,
          parent_id: root_task.id,
          assigned_by: assigner,
          instructions: [old_instructions]
        )
      end

      let!(:child_task) do
        create(
          :ama_colocated_task,
          :ihp,
          appeal: parent_task.appeal,
          parent: parent_task,
          assigned_by: assigner,
          assigned_to: create(:user),
          instructions: [old_instructions]
        )
      end

      it "returns an error" do
        subject

        expect(response.status).to eq(403)
      end
    end
  end
end
