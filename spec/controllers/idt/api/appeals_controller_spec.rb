RSpec.describe Idt::Api::V1::AppealsController, type: :controller do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  describe "GET /idt/api/v1/appeals" do
    let(:user) { create(:user, css_id: "TEST_ID", full_name: "George Michael") }

    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

    context "when request header does not contain token" do
      it "response should error" do
        get :list
        expect(response.status).to eq 400
      end
    end

    context "when request header contains invalid token" do
      before { request.headers["TOKEN"] = "3289fn893rnqi8hf3nf" }

      it "responds with an error" do
        get :list
        expect(response.status).to eq 403
      end
    end

    context "when request header contains inactive token" do
      before do
        _key, t = Idt::Token.generate_one_time_key_and_proposed_token
        request.headers["TOKEN"] = t
      end

      it "responds with an error" do
        get :list
        expect(response.status).to eq 403
      end
    end

    context "when request header contains valid token" do
      context "and user is not an attorney" do
        before do
          create(:user, css_id: "ANOTHER_TEST_ID")
          key, t = Idt::Token.generate_one_time_key_and_proposed_token
          Idt::Token.activate_proposed_token(key, "ANOTHER_TEST_ID")
          request.headers["TOKEN"] = t
        end

        it "returns an error", skip: "fails intermittently, debugging in future PR" do
          get :list
          expect(response.status).to eq 403
        end
      end

      context "and user is an attorney" do
        let(:role) { :attorney_role }

        before do
          create(:staff, role, sdomainid: user.css_id)
          request.headers["TOKEN"] = token
        end

        let!(:appeals) do
          [
            create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)),
            create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user))
          ]
        end

        context "and appeal id URL parameter not is passed" do
          it "succeeds" do
            get :list
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["data"]
            expect(response_body.first["attributes"]["veteran_first_name"]).to eq appeals.first.veteran_first_name
            expect(response_body.first["attributes"]["veteran_last_name"]).to eq appeals.first.veteran_last_name
            expect(response_body.first["attributes"]["file_number"]).to eq appeals.first.veteran_file_number

            expect(response_body.second["attributes"]["veteran_first_name"]).to eq appeals.second.veteran_first_name
            expect(response_body.second["attributes"]["veteran_last_name"]).to eq appeals.second.veteran_last_name
            expect(response_body.second["attributes"]["file_number"]).to eq appeals.second.veteran_file_number
          end
        end

        context "and legacy appeal id URL parameter is passed" do
          let(:params) { { appeal_id: appeals.first.vacols_id } }

          it "succeeds and passes appeal info" do
            get :details, params: params
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["data"]

            expect(response_body["attributes"]["veteran_first_name"]).to eq appeals.first.veteran_first_name
            expect(response_body["attributes"]["veteran_last_name"]).to eq appeals.first.veteran_last_name
            expect(response_body["attributes"]["file_number"]).to eq appeals.first.veteran_file_number
            expect(response_body["attributes"]["representative_type"]).to eq(
              appeals.first.power_of_attorney.vacols_representative_type
            )
            expect(response_body["attributes"]["aod"]).to eq appeals.first.aod
            expect(response_body["attributes"]["cavc"]).to eq appeals.first.cavc
            expect(response_body["attributes"]["issues"]).to eq appeals.first.issues
            expect(response_body["attributes"]["status"]).to eq appeals.first.status
            expect(response_body["attributes"]["veteran_is_deceased"]).to eq !!appeals.first.notice_of_death_date
            expect(response_body["attributes"]["appellant_is_not_veteran"]).to eq !!appeals.first.appellant_first_name
          end

          context "and case is selected for quality review and has outstanding mail" do
            let(:assigner) { create(:user, css_id: "ANOTHER_TEST_ID", full_name: "Lyor Cohen") }

            let(:appeals) do
              c = create(:case,
                         :outstanding_mail,
                         :selected_for_quality_review,
                         :assigned,
                         user: user,
                         document_id: "1234",
                         assigner: assigner)
              [create(:legacy_appeal, vacols_case: c)]
            end

            it "returns the correct values" do
              get :details, params: params
              expect(response.status).to eq 200
              response_body = JSON.parse(response.body)["data"]

              expect(response_body["attributes"]["previously_selected_for_quality_review"]).to eq true
              expect(response_body["attributes"]["outstanding_mail"]).to eq true
              document = response_body["attributes"]["documents"][0]
              expect(document["assigned_by"]).to eq "Lyor Cohen"
              expect(document["written_by"]).to eq "George Michael"
              expect(document["document_id"]).to eq "1234"
            end
          end
        end
      end
    end
  end
end
