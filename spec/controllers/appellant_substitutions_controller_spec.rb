# frozen_string_literal: true

RSpec.describe AppellantSubstitutionsController, type: :controller do
  before do
    Fakes::Initializer.load!
    User.authenticate!(user: cob_user)
  end

  let!(:cob_user) do
    ClerkOfTheBoard.singleton.add_user(create(:user))
    ClerkOfTheBoard.singleton.users.first
  end

  shared_examples "required ClerkOfTheBoard user" do
    context "without a ClerkOfTheBoard user" do
      it "does not create the Appellant Substitution" do
        User.authenticate!(user: create(:user))
        subject

        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)["errors"][0]["title"])
          .to eq("Only Clerk of the Board users can create Appellant Substitutions")
      end
    end
  end

  describe "POST /appeals/:appeal_id/appellant_substitutions" do
    let(:source_appeal) { create(:appeal, :dispatched) }
    let(:source_appeal_id) { source_appeal.uuid }
    let(:substitution_date) { 5.days.ago.to_date }
    let(:substitute_participant_id) { 123 }
    let(:poa_participant_id) { 789 }

    let(:params) do
      {
        appeal_id: source_appeal_id, # from URL
        source_appeal_id: source_appeal_id,
        substitution_date: substitution_date,
        claimant_type: DependentClaimant.name,
        substitute_participant_id: substitute_participant_id,
        poa_participant_id: poa_participant_id,
        selected_task_ids: [],
        task_params: {}
      }
    end

    subject { post :create, params: params }

    shared_examples "creates Appellant Substitution" do
      it "creates the Appellant Substitution and new appeal" do
        substitution_count = AppellantSubstitution.count
        subject

        expect(response.status).to eq(201)
        response_body = JSON.parse(response.body)

        expect(response_body["substitution"]["source_appeal_id"]).to eq(source_appeal.id)
        expect(AppellantSubstitution.count).to eq(substitution_count + 1)

        expect(response_body["targetAppeal"]["id"])
          .to eq(AppellantSubstitution.find(response_body["substitution"]["id"]).target_appeal_id)
        expect(response_body["targetAppeal"]["stream_docket_number"]).to eq(source_appeal.docket_number)
        expect(response_body["targetAppeal"]["stream_type"]).to eq(source_appeal.stream_type)
      end
    end

    context "with a ClerkOfTheBoard user" do
      context "when insufficient parameters are provided" do
        let(:substitute_participant_id) { nil }
        it "does not create the Appellant Substitution" do
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(ActionController::ParameterMissing)
          end
        end
      end

      context "when correct parameters are provided" do
        include_examples "creates Appellant Substitution"
      end
    end

    include_examples "required ClerkOfTheBoard user"
  end
end
