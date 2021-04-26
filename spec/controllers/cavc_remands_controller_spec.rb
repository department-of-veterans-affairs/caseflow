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

  shared_examples "required cavc lit support user" do
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

  describe "POST /appeals/:appeal_id/cavc_remands" do
    let(:source_appeal) { create(:appeal, :dispatched) }
    let(:source_appeal_id) { source_appeal.uuid }
    let(:cavc_docket_number) { "123-1234567" }
    let(:represented_by_attorney) { true }
    let(:cavc_judge_full_name) { Constants::CAVC_JUDGE_FULL_NAMES.first }
    let(:cavc_decision_type) { Constants::CAVC_DECISION_TYPES["remand"] }
    let(:remand_subtype) { Constants::CAVC_REMAND_SUBTYPES["jmr"] }
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
    let(:federal_circuit) { nil }
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
        federal_circuit: federal_circuit,
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
        expect(response_body["cavc_remand"]["federal_circuit"]).to eq(federal_circuit)
        expect(CavcRemand.count).to eq(remand_count + 1)

        expect(response_body["cavc_appeal"]["id"])
          .to eq(CavcRemand.find(response_body["cavc_remand"]["id"]).remand_appeal_id)
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

      shared_examples "works without judgement and mandate date parameters" do
        context "without judgement and mandate date parameters" do
          let(:judgement_date) { nil }
          let(:mandate_date) { nil }
          include_examples "creates a remand depending on the sub-type"
        end
      end

      context "when sub-type is MDR" do
        let(:remand_subtype) { Constants::CAVC_REMAND_SUBTYPES["mdr"] }
        let(:federal_circuit) { false }

        context "with judgement and mandate date parameters" do
          include_examples "creates a remand depending on the sub-type"
        end

        include_examples "works without judgement and mandate date parameters"

        it "sets federal circuit DB field to false" do
          subject
          expect(response.status).to eq(201)
          response_body = JSON.parse(response.body)
          expect(response_body["cavc_remand"]["federal_circuit"]).to eq false
        end

        context "when federal circuit boolean is set" do
          let(:federal_circuit) { true }
          it "sets federal circuit DB field" do
            subject
            expect(response.status).to eq(201)
            response_body = JSON.parse(response.body)
            expect(response_body["cavc_remand"]["federal_circuit"]).to eq true
          end
        end
      end

      context "when type is straight_reversal" do
        let(:cavc_decision_type) { Constants::CAVC_DECISION_TYPES["straight_reversal"] }
        let(:remand_subtype) { nil }

        include_examples "works without judgement and mandate date parameters"
      end

      context "when type is death_dismissal" do
        let(:cavc_decision_type) { Constants::CAVC_DECISION_TYPES["death_dismissal"] }
        let(:remand_subtype) { nil }

        include_examples "works without judgement and mandate date parameters"
      end
    end

    include_examples "required cavc lit support user"
  end

  describe "PATCH /appeals/:appeal_id/cavc_remands via add_cavc_dates_modal" do
    # create an existing cavc remand
    let(:cavc_remand) { create(:cavc_remand, :mdr) }
    let(:remand_appeal_id) { cavc_remand.remand_appeal_id }
    let(:remand_appeal_uuid) { Appeal.find(cavc_remand.remand_appeal_id).uuid }
    let(:judgement_date) { 2.days.ago }
    let(:mandate_date) { 2.days.ago }
    let(:instructions) { "Do this!" }
    let(:params) do
      {
        source_form: "add_cavc_dates_modal",
        remand_appeal_id: remand_appeal_uuid,
        appeal_id: remand_appeal_uuid,
        judgement_date: judgement_date,
        mandate_date: mandate_date,
        instructions: instructions
      }
    end

    subject { patch :update, params: params }

    context "with a Lit Support User" do
      context "with insufficient parameters" do
        let(:mandate_date) { nil }

        it "does not create the CAVC remand" do
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(ActionController::ParameterMissing)
          end
        end
      end

      context "with sufficient parameters" do
        it "does not create new objects" do
          Appeal.find(remand_appeal_id)
          remand_count = CavcRemand.count
          cavc_count = Appeal.court_remand.count

          expect { subject }.not_to raise_error

          expect(CavcRemand.count).to eq(remand_count)
          expect(Appeal.court_remand.count).to eq(cavc_count)
        end

        it "does not change the Remand appeal" do
          existing_remand = Appeal.find(remand_appeal_id)
          expect { subject }.not_to raise_error
          response_body = JSON.parse(response.body)
          expect(response_body["cavc_appeal"]["id"]).to eq(existing_remand.reload.id)
          expect(response_body["cavc_appeal"]["updated_at"].to_date).to eq(existing_remand.updated_at.to_date)
        end

        it "updates the CAVC remand" do
          existing_remand = Appeal.find(remand_appeal_id)
          old_instructions = cavc_remand.instructions

          expect { subject }.not_to raise_error

          expect(response.status).to eq(200)
          response_body = JSON.parse(response.body)

          expect(response_body["cavc_remand"]["remand_appeal_id"]).to eq(existing_remand.reload.id)
          expect(response_body["cavc_remand"]["judgement_date"].to_date).to eq(judgement_date.to_date)
          expect(response_body["cavc_remand"]["mandate_date"].to_date).to eq(mandate_date.to_date)
          expect(response_body["cavc_remand"]["instructions"]).to include(instructions)
          expect(response_body["cavc_remand"]["instructions"]).to include(old_instructions)
        end
      end
    end

    include_examples "required cavc lit support user"
  end

  describe "PATCH /appeals/:appeal_id/cavc_remands without cavc_dates_modal in the params" do
    let(:source_appeal) { create(:appeal) }
    let(:source_appeal_id) { source_appeal.uuid }
    let(:cavc_remand) { create(:cavc_remand, :mdr) }
    let(:cavc_docket_number) { "123-1234567" }
    let(:remand_appeal_id) { cavc_remand.remand_appeal_id }
    let(:remand_appeal_uuid) { Appeal.find(cavc_remand.remand_appeal_id).uuid }
    let(:cavc_judge_full_name) { Constants::CAVC_JUDGE_FULL_NAMES.first }
    let(:cavc_decision_type) { Constants::CAVC_DECISION_TYPES["remand"] }
    let(:federal_circuit) { false }
    let(:remand_subtype) { Constants::CAVC_REMAND_SUBTYPES["mdr"] }
    let(:instructions) { "update only the instructions!!" }
    let(:decision_date) { 7.days.ago }
    let(:judgement_date) { 6.days.ago.to_date }
    let(:mandate_date) { 3.days.ago.to_date }
    let(:decision_issues) do
      create_list(
        :decision_issue,
        2,
        :rating,
        decision_review: source_appeal,
        disposition: "remanded",
        description: "description here",
        decision_text: "decision issue"
      )
    end
    let(:decision_issue_ids) { decision_issues.map(&:id) }
    let(:params) do
      {
        source_appeal_id: source_appeal_id,
        remand_appeal_id: remand_appeal_uuid,
        appeal_id: remand_appeal_uuid,
        cavc_docket_number: cavc_docket_number,
        cavc_judge_full_name: cavc_judge_full_name,
        cavc_decision_type: cavc_decision_type,
        remand_subtype: remand_subtype,
        instructions: instructions,
        decision_date: decision_date,
        judgement_date: judgement_date,
        mandate_date: mandate_date,
        decision_issue_ids: decision_issue_ids,
        represented_by_attorney: true,
        federal_circuit: federal_circuit
      }
    end

    subject { patch :update, params: params }

    it "updates the CAVC remand" do
      existing_remand = Appeal.find(remand_appeal_id)

      expect { subject }.not_to raise_error

      expect(response.status).to eq(200)
      response_body = JSON.parse(response.body)

      expect(response_body["cavc_remand"]["remand_appeal_id"]).to eq(existing_remand.reload.id)
      expect(response_body["cavc_remand"]["instructions"]).to eq(instructions)
    end
  end
end
