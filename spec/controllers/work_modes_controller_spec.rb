# frozen_string_literal: true

RSpec.describe WorkModesController, :all_dbs, type: :controller do
  describe "POST /appeals/:appeal_id/work_mode" do
    before { FeatureToggle.enable!(:overtime_revamp) }

    after { FeatureToggle.disable!(:overtime_revamp) }

    let(:judge) { create(:user) }
    let!(:vacols_judge) { create(:staff, :judge_role, user: judge) }

    before { User.authenticate!(user: judge) }

    let(:overtime_value) { true }
    subject { post :create, params: { overtime: overtime_value, appeal_id: appeal_id } }

    context "for invalid appeal_id" do
      let(:appeal_id) { -1 }
      it "returns 404" do
        subject
        expect(response.status).to eq(404)
      end
    end

    shared_examples "an appeal with overtime" do
      context "when overtime parameter is nil or not provided" do
        let(:overtime_value) { nil }
        it "raises error" do
          expect { subject }.to raise_error(ActionController::ParameterMissing)
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

    context "for AMA appeal" do
      let!(:judge_assign_task) { create(:ama_judge_task, parent: create(:root_task), assigned_to: judge) }
      let(:appeal) { judge_assign_task.appeal }
      let(:appeal_id) { appeal.uuid }

      it_behaves_like "an appeal with overtime"
    end

    context "for legacy appeal" do
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, :assigned, user: judge)) }
      let(:appeal_id) { appeal.vacols_id }

      let(:root_task) { create(:root_task, appeal: appeal) }
      let!(:judge_assign_task) { JudgeAssignTask.create!(appeal: appeal, parent: root_task, assigned_to: judge) }

      it_behaves_like "an appeal with overtime"
    end
  end
end
