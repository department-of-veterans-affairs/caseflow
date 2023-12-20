# frozen_string_literal: true

RSpec.describe DocketSwitchesController, :postgres, type: :controller do
  describe "#create" do
    before do
      FeatureToggle.enable!(:docket_switch)
      cotb_org.add_user(cotb_attorney)
      create(:staff, :judge_role, sdomainid: judge.css_id)
    end
    after { FeatureToggle.disable!(:docket_switch) }

    let(:cotb_org) { ClerkOfTheBoard.singleton }
    let(:receipt_date) { Time.zone.today - 20 }
    let(:appeal) do
      create(:appeal, receipt_date: receipt_date)
    end

    let(:root_task) { create(:root_task, :completed, appeal: appeal) }
    let(:cotb_attorney) { create(:user, :with_vacols_attorney_record, full_name: "Clark Bard") }
    let(:judge) { create(:user, :with_vacols_judge_record, full_name: "Judge the First", css_id: "JUDGE_1") }

    before { User.authenticate!(user: cotb_attorney) }

    context "when attorney has been assigned docket switch denied task" do
      let(:params) do
        {
          old_docket_stream_id: appeal.id,
          task_id: docket_switch_denied_task.id,
          disposition: "denied",
          receipt_date: receipt_date
        }
      end

      let!(:docket_switch_denied_task) do
        create(
          :docket_switch_denied_task,
          appeal: appeal,
          # parent: root_task,
          assigned_to: cotb_attorney,
          assigned_by: judge
        )
      end
      it "should create docket switch" do
        get :create, params: params
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body.count).to eq 1
      end
    end
  end
end
