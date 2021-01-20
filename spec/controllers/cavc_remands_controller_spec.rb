# frozen_string_literal: true

RSpec.describe CavcRemandsController, type: :controller do
  before do
    Fakes::Initializer.load!
    User.authenticate!(user: lit_support_user)
  end

  let!(:lit_support_user) do
    CavcLitigationSupport.singleton.add_user(create(:user))
    CavcLitigationSupport.singleton.users.first
  end

  describe "POST /appeals/:appeal_id/cavc_remands" do
    let(:source_appeal) { create(:appeal) }
    let(:source_appeal_id) { source_appeal.uuid }
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
        decision_review: source_appeal,
        disposition: "denied",
        description: "Decision issue description",
        decision_text: "decision issue"
      )
    end
    let(:decision_issue_ids) { decision_issues.map(&:id) }
    let(:instructions) { "Intructions!" }

    let(:params) do
      {
        source_appeal_id: source_appeal_id,
        appeal_id: source_appeal_id,
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

    shared_examples "creates a remand depending on the sub-type" do
      it "creates the CAVC remand and new appeal" do
        remand_count = CavcRemand.count
        cavc_count = Appeal.court_remand.count
        subject

        expect(response.status).to eq(201)
        response_body = JSON.parse(response.body)

        expect(response_body["cavc_remand"]["source_appeal_id"]).to eq(source_appeal.id)
        expect(response_body["cavc_remand"]["decision_issue_ids"]).to match_array(decision_issue_ids)
        expect(CavcRemand.count).to eq(remand_count + 1)

        expect(response_body["cavc_appeal"]["id"]).to eq(CavcRemand.find(response_body["cavc_remand"]["id"]).remand_appeal_id)
        expect(response_body["cavc_appeal"]["stream_docket_number"]).to eq(source_appeal.docket_number)
        expect(response_body["cavc_appeal"]["stream_type"]).to eq(Appeal.stream_types["court_remand"])
        expect(Appeal.court_remand.count).to eq(cavc_count + 1)
      end
    end

    context "with a Lit Support User" do
      context "when sub-type is JMR with insufficient parameters" do
        let(:cavc_docket_number) { nil }
        it "does not create the CAVC remand" do
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(ActionController::ParameterMissing)
          end
        end
      end

      context "when sub-type is JMR with correct parameters" do
        include_examples "creates a remand depending on the sub-type"
      end

      context "when sub-type is MDR" do
        let(:remand_subtype) { Constants::CAVC_REMAND_SUBTYPES["mdr"] }
        context "with judgement and mandate date parameters" do
          include_examples "creates a remand depending on the sub-type"
        end

        context "without judgement and mandate date parameters" do
          let(:judgement_date) { nil }
          let(:mandate_date) { nil }
          include_examples "creates a remand depending on the sub-type"
        end
      end
    end

    context "without a Lit Support User" do
      it "does not create the CAVC remand" do
        User.authenticate!(user: create(:user))
        subject

        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)["errors"][0]["title"])
          .to eq("Only CAVC Litigation Support users can create CAVC Remands")
      end
    end
  end
end
