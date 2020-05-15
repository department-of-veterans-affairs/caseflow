# frozen_string_literal: true

RSpec.describe WorkModesController, :all_dbs, type: :controller do
  describe "POST /appeals/:appeal_id/work_mode" do
    before { FeatureToggle.enable!(:overtime_revamp) }

    after { FeatureToggle.disable!(:overtime_revamp) }

    let(:judge) { create(:user) }
    let!(:vacols_judge) { create(:staff, :judge_role, user: judge) }

    let(:current_user) { judge }

    before { User.authenticate!(user: current_user) }

    let(:overtime_value) { true }
    subject { post :create, params: { overtime: overtime_value, appeal_id: appeal_id } }

    context "for invalid appeal_id" do
      let(:appeal_id) { -1 }
      it "returns 404" do
        subject
        expect(response.status).to eq(404)
      end
    end

    shared_examples "an appeal that can be worked overtime" do
      context "when overtime parameter is nil or not provided" do
        let(:overtime_value) { nil }
        it "raises error" do
          expect { subject }.to raise_error(ActionController::ParameterMissing)
        end
      end

      context "when overtime cannot be updated" do
        context "when appeal.work_mode cannot update" do
          before do
            appeal.work_mode = WorkMode.create_or_update_by_appeal(appeal, overtime: false)
            expect(appeal.work_mode).to receive(:update).and_return(false)
          end
          it "raises error" do
            expect { WorkMode.create_or_update_by_appeal(appeal, overtime: overtime_value) }
              .to raise_error(Caseflow::Error::WorkModeCouldNotUpdateError)
          end
        end
        context "when WorkMode.create_or_update_by_appeal throws error" do
          before do
            expect(WorkMode).to receive(:create_or_update_by_appeal)
              .and_raise(Caseflow::Error::WorkModeCouldNotUpdateError)
          end
          it "returns error status" do
            subject
            expect(response.status).to eq(500)
          end
        end
      end

      context "when appeal's overtime is not yet set" do
        context "when setting overtime to true" do
          it "sets overtime to true" do
            expect(appeal.work_mode).to be_nil
            expect(appeal.overtime?).to eq(false)
            expect { subject }.to change(WorkMode, :count).by(1)
            expect(appeal.reload.overtime?).to eq(true)
            expect(response.status).to eq(200)
            expect(JSON.parse(response.body)["work_mode"]["overtime"]).to eq(true)
          end
        end

        context "when setting overtime to false" do
          let(:overtime_value) { false }
          it "sets overtime to false" do
            expect(appeal.work_mode).to be_nil
            expect(appeal.overtime?).to eq(false)
            expect { subject }.to change(WorkMode, :count).by(1)
            expect(appeal.reload.overtime?).to eq(false)
            expect(response.status).to eq(200)
            expect(JSON.parse(response.body)["work_mode"]["overtime"]).to eq(false)
          end
        end
      end

      context "when changing existing overtime from true to false" do
        before do
          appeal.work_mode = WorkMode.create_or_update_by_appeal(appeal, overtime: true)
        end
        let(:overtime_value) { false }
        it "sets overtime to false" do
          expect(appeal.work_mode).not_to be_nil
          expect(appeal.overtime?).to eq(true)
          expect { subject }.to change(WorkMode, :count).by(0)
          expect(appeal.reload.overtime?).to eq(false)
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)["work_mode"]["overtime"]).to eq(false)
        end

        it "sets overtime to false using 0" do
          expect(appeal.work_mode).not_to be_nil
          expect(appeal.overtime?).to eq(true)
          count_before = WorkMode.count
          post :create, params: { overtime: 0, appeal_id: appeal_id }
          expect(WorkMode.count).to eq(count_before)
          expect(appeal.reload.overtime?).to eq(false)
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)["work_mode"]["overtime"]).to eq(false)
        end
      end
    end

    let(:attorney) { create(:user) }
    let!(:attorney_staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }

    context "for AMA appeal" do
      let(:root_task) { create(:root_task) }
      let(:judge_assign_task) { create(:ama_judge_assign_task, parent: root_task, assigned_to: judge) }
      let(:appeal) { judge_assign_task.appeal }
      let(:appeal_id) { appeal.uuid }

      it_behaves_like "an appeal that can be worked overtime"

      context "when appeal is assigned to attorney" do
        before { judge_assign_task.completed! }

        let(:judge_review_task) { create(:ama_judge_decision_review_task, parent: root_task, assigned_to: judge) }
        let!(:attorney_task) { create(:ama_attorney_task, assigned_to: attorney, parent: judge_review_task) }

        it_behaves_like "an appeal that can be worked overtime"
      end
    end

    context "for legacy appeal" do
      let(:vacols_case) { create(:case, :assigned, user: judge, as_judge_assign_task: true) }
      let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
      let(:appeal_id) { appeal.vacols_id }

      it "should have an appeal with a JudgeLegacyAssignTask" do
        expect(LegacyWorkQueue.tasks_by_appeal_id(appeal.vacols_id).map(&:class)).to eq([JudgeLegacyAssignTask])
      end

      it_behaves_like "an appeal that can be worked overtime"

      context "when appeal is assigned to attorney" do
        let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, :assigned, user: attorney)) }

        it "should have an appeal with a AttorneyLegacyTask" do
          expect(LegacyWorkQueue.tasks_by_appeal_id(appeal.vacols_id).map(&:class)).to eq([AttorneyLegacyTask])
        end

        before do
          allow_any_instance_of(AttorneyLegacyTask).to receive(:assigned_by).and_return(
            OpenStruct.new(
              first_name: judge.full_name,
              last_name: judge.full_name,
              pg_id: judge.id
            )
          )
        end

        it_behaves_like "an appeal that can be worked overtime"
      end
    end

    context "when non-judge user modifies overtime" do
      let(:current_user) { create(:user) }

      let(:judge_assign_task) { create(:ama_judge_assign_task, parent: create(:root_task), assigned_to: judge) }

      let(:appeal) { judge_assign_task.appeal }
      let(:appeal_id) { appeal.uuid }

      shared_examples "unauthorized user toggles overtime" do
        it "returns error" do
          expect(appeal.work_mode).to be_nil
          expect(appeal.overtime?).to eq(false)
          subject
          expect(appeal.reload.overtime?).to eq(false)
          expect(response.status).to eq(403)
        end
      end

      context "when user is any user" do
        include_examples "unauthorized user toggles overtime"
      end

      context "when user is an attorney assigned to the case" do
        let!(:vacols_attorney) { create(:staff, :attorney_role, user: current_user) }

        let(:judge_review_task) { create(:ama_judge_decision_review_task, parent: create(:root_task)) }
        let(:attorney_task) do
          create(
            :ama_attorney_task,
            parent: judge_review_task,
            assigned_by: judge,
            assigned_to: current_user
          )
        end
        let(:judge_assign_task) { create(:ama_judge_assign_task, parent: attorney_task.root_task, assigned_to: judge) }

        include_examples "unauthorized user toggles overtime"
      end
    end
  end
end
