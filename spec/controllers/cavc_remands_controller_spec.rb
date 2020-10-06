# frozen_string_literal: true

RSpec.describe CavcRemandsController, type: :controller do
  before do
    Fakes::Initializer.load!
    User.authenticate!(user: lit_support_user)
  end

  let!(:lit_support_user) do
    LitigationSupport.singleton.add_user(create(:user))
    LitigationSupport.singleton.users.first
  end

  describe "POST /appeals/:appeal_id/cavc_remands" do
    let(:appeal) { create(:appeal) }
    let(:appeal_id) { appeal.id }
    let(:cavc_docket_number) { "123-1234567" }
    let(:represented_by_attorney) { true }
    let(:cavc_judge_full_name) { Constants::CAVC_JUDGE_FULL_NAMES.first }
    let(:cavc_decision_type) { Constants::CAVC_DECISION_TYPES.keys.first }
    let(:remand_subtype) { Constants::CAVC_REMAND_SUBTYPES.keys.first }
    let(:decision_date) { 5.days.ago.to_date }
    let(:judgement_date) { 4.days.ago.to_date }
    let(:mandate_date) { 3.days.ago.to_date }
    let(:decision_issues) do
      create_list(
        :decision_issue,
        3,
        :rating,
        decision_review: appeal,
        disposition: "denied",
        description: "Decision issue description",
        decision_text: "decision issue"
      )
    end
    let(:decision_issue_ids) { decision_issues.map(&:id) }
    let(:instructions) { "Intructions!" }

    let(:params) do
      {
        appeal_id: appeal_id,
        cavc_docket_number: cavc_docket_number,
        represented_by_attorney: represented_by_attorney,
        cavc_judge_full_name: cavc_judge_full_name,
        cavc_decision_type: cavc_decision_type,
        remand_subtype: remand_subtype,
        decision_date: decision_date,
        judgement_date: judgement_date,
        mandate_date: mandate_date,
        decision_issue_ids: decision_issue_ids,
        instructions: instructions
      }
    end

    subject { post :create, params: params }

    context "with a Lit Support User" do
      context "with insufficient parameters" do
        it "does not create the CAVC remand" do
          params.delete(:cavc_docket_number)
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(ActionController::ParameterMissing)
          end
        end
      end

      context "with correct parameters" do
        it "creates the CAVC remand" do
          subject

          expect(JSON.parse(response.body)["cavc_remand"]["appeal_id"]).to eq(appeal_id)
          expect(response.status).to eq(201)
        end
      end
    end

    context "without a Lit Support User" do
      it "does not create the CAVC remand" do
        User.authenticate!(user: create(:user))
        subject

        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)["errors"][0]["title"])
          .to eq("Only Litigation Support users can create CAVC Remands")
      end
    end
  end
end
