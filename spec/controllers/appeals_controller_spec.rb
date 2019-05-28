# frozen_string_literal: true

RSpec.describe AppealsController, type: :controller do
  include TaskHelpers

  describe "GET appeals" do
    let(:ssn) { Generators::Random.unique_ssn }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "#{ssn}S")) }
    let(:options) { { format: :json } }
    let(:veteran_id) { appeal.sanitized_vbms_id }

    context "when current user is a System Admin" do
      before { User.authenticate!(roles: ["System Admin"]) }

      context "when request header does not contain Veteran ID" do
        it "responds with an error" do
          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response_body["errors"][0]["title"]).to eq "Veteran file number missing"
          expect(response.status).to eq 400
        end
      end

      context "when request header contains Veteran file number with associated appeals and claim reviews" do
        it "returns valid response with one appeal" do
          create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)
          request.headers["HTTP_VETERAN_ID"] = veteran_id
          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 200
          expect(response_body["appeals"].size).to eq 1
          expect(response_body["claim_reviews"].size).to eq 1
        end
      end

      context "when request header contains existing Veteran ID with no associated appeals" do
        it "returns valid response with empty appeals array" do
          veteran_without_associated_appeals = create(:veteran)
          request.headers["HTTP_VETERAN_ID"] = veteran_without_associated_appeals.file_number
          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 200
          expect(response_body["appeals"].size).to eq 0
          expect(response_body["claim_reviews"].size).to eq 0
        end
      end

      context "with invalid Veteran file number" do
        it "returns valid response with empty appeals array" do
          request.headers["HTTP_VETERAN_ID"] = "invalid_file_number"
          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 200
          expect(response_body["appeals"].size).to eq 0
          expect(response_body["claim_reviews"].size).to eq 0
        end
      end
    end

    context "when the current user is a VSO employee" do
      context "and does not have access to the file" do
        it "responds with an error" do
          request.headers["HTTP_VETERAN_ID"] = veteran_id
          Fakes::BGSService.inaccessible_appeal_vbms_ids = [appeal.veteran_file_number]
          User.authenticate!(roles: ["VSO"])

          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response_body["errors"][0]["title"]).to eq "Access to Veteran file prohibited"
        end
      end

      context "veteran does not exist and VSO employee does not have access to the file" do
        it "responds with an error" do
          request.headers["HTTP_VETERAN_ID"] = "123"
          Fakes::BGSService.inaccessible_appeal_vbms_ids = [appeal.veteran_file_number, "123"]
          User.authenticate!(roles: ["VSO"])
          expect_any_instance_of(Fakes::BGSService).to_not receive(:fetch_poas_by_participant_id)

          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response_body["errors"][0]["title"]).to eq "Access to Veteran file prohibited"
        end
      end

      context "and has access to the file" do
        it "responds with appeals and claim reviews" do
          appeal = create(:appeal, claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
          create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)
          vso_user = create(:user, :vso_role, css_id: "BVA_VSO")
          User.authenticate!(user: vso_user)
          request.headers["HTTP_VETERAN_ID"] = appeal.veteran_file_number

          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response_body["appeals"].size).to eq 1
          expect(response_body["claim_reviews"].size).to eq 1
        end
      end

      context "when request header contains nonexistent Veteran file number" do
        it "returns 404 error" do
          appeal = create(:appeal, claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
          create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)
          vso_user = create(:user, :vso_role, css_id: "BVA_VSO")
          User.authenticate!(user: vso_user)
          request.headers["HTTP_VETERAN_ID"] = "123"

          expect_any_instance_of(Fakes::BGSService).to_not receive(:fetch_poas_by_participant_id)

          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 404
          expect(response_body["errors"][0]["title"]).to eq "Veteran not found"
        end
      end

      context "when request header contains Veteran ID with no associated appeals" do
        it "returns valid response with empty appeals array" do
          appeal = create(:appeal, claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
          create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)
          vso_user = create(:user, :vso_role, css_id: "BVA_VSO")
          veteran_without_associated_appeals = create(:veteran)
          User.authenticate!(user: vso_user)
          request.headers["HTTP_VETERAN_ID"] = veteran_without_associated_appeals.file_number

          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 200
          expect(response_body["appeals"].size).to eq 0
          expect(response_body["claim_reviews"].size).to eq 0
        end
      end
    end
  end

  describe "GET appeals/appeal_id/document_count" do
    let(:appeal) { create(:appeal) }

    before { User.authenticate!(roles: ["System Admin"]) }

    context "when a legacy appeal has documents" do
      let(:documents) do
        [
          create(:document, type: "SSOC", received_at: 6.days.ago),
          create(:document, type: "SSOC", received_at: 7.days.ago)
        ]
      end
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfkey: "654321", documents: documents)) }

      it "should return document count and not call vbms" do
        get :document_count, params: { appeal_id: appeal.vacols_id }

        response_body = JSON.parse(response.body)
        expect(response_body["document_count"]).to eq documents.length
      end
    end

    context "when an ama appeal has documents" do
      before do
        allow(EFolderService).to receive(:document_count) { documents.length }
      end

      let(:file_number) { Random.rand(999_999_999).to_s }

      let!(:documents) do
        [
          create(:document, type: "SSOC", received_at: 6.days.ago, file_number: file_number),
          create(:document, type: "SSOC", received_at: 7.days.ago, file_number: file_number)
        ]
      end
      let(:appeal) { create(:appeal, veteran_file_number: file_number) }

      it "should return document count" do
        get :document_count, params: { appeal_id: appeal.uuid }

        response_body = JSON.parse(response.body)
        expect(response_body["document_count"]).to eq 2
      end
    end

    context "when appeal is not found" do
      it "should return status 404" do
        get :document_count, params: { appeal_id: "123456" }
        expect(response.status).to eq 404
      end
    end

    context "when efolder returns an access forbidden error" do
      let(:err_code) { 403 }
      let(:err_msg) do
        "This efolder contains sensitive information you do not have permission to view." \
          " Please contact your supervisor."
      end

      before do
        allow(EFolderService).to receive(:document_count) do
          fail Caseflow::Error::EfolderAccessForbidden, code: err_code, message: err_msg
        end
      end

      it "responds with a 4xx and error message" do
        User.authenticate!(roles: ["System Admin"])
        get :document_count, params: { appeal_id: appeal.external_id }
        response_body = JSON.parse(response.body)

        expect(response.status).to eq(err_code)
        expect(response_body["errors"].length).to eq(1)
        expect(response_body["errors"][0]["title"]).to eq(err_msg)
      end
    end

    context "when application encounters a generic error" do
      let(:err_msg) { "Some application error" }

      before { allow(EFolderService).to receive(:document_count) { fail err_msg } }

      it "responds with a 500 and error message" do
        User.authenticate!(roles: ["System Admin"])
        get :document_count, params: { appeal_id: appeal.external_id }
        response_body = JSON.parse(response.body)

        expect(response.status).to eq(500)
        expect(response_body["errors"].length).to eq(1)
        expect(response_body["errors"][0]["title"]).to eq(err_msg)
      end
    end
  end

  describe "GET cases/:id" do
    context "Legacy Appeal" do
      let(:the_case) { FactoryBot.create(:case) }
      let!(:appeal) { FactoryBot.create(:legacy_appeal, :with_veteran, vacols_case: the_case) }
      let!(:higher_level_review) { create(:higher_level_review, veteran_file_number: appeal.veteran_file_number) }
      let!(:supplemental_claim) { create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number) }
      let!(:options) { { caseflow_veteran_id: veteran_id, format: request_format } }

      context "when current user is a System Admin" do
        before { User.authenticate!(roles: ["System Admin"]) }

        context "when requesting html response" do
          let(:request_format) { :html }

          context "with valid Veteran ID" do
            let(:veteran_id) { appeal.veteran.id }

            it "should return the single page app" do
              get :show_case_list, params: options
              expect(response.status).to eq 200
            end
          end

          context "with invalid Veteran ID" do
            let(:veteran_id) { "invalidID" }

            it "should return the single page app" do
              get :show_case_list, params: options
              expect(response.status).to eq 200
            end
          end
        end

        context "when requesting json response" do
          let(:request_format) { :json }

          context "with valid Veteran ID" do
            let(:veteran_id) { appeal.veteran.id }

            it "should return a list of appeals for the Veteran" do
              get :show_case_list, params: options
              expect(response.status).to eq 200
              response_body = JSON.parse(response.body)

              expect(response_body["appeals"].size).to eq 1
              expect(response_body["claim_reviews"].size).to eq 2
            end
          end

          context "with invalid Veteran ID" do
            let(:veteran_id) { "invalidID" }

            it "should return a 404" do
              get :show_case_list, params: options
              response_body = JSON.parse(response.body)

              expect(response_body["errors"][0]["title"]).to eq "Veteran not found"
              expect(response.status).to eq 404
            end
          end
        end
      end

      context "when current user is a VSO employee" do
        before { User.authenticate!(roles: ["VSO"]) }

        context "when requesting json response" do
          let(:request_format) { :json }

          context "with valid Veteran ID" do
            let!(:veteran_id) { appeal.veteran.id }

            it "returns an empty list of appeals and 2 claim reviews for the Veteran" do
              get :show_case_list, params: options
              response_body = JSON.parse(response.body)

              expect(response.status).to eq 200
              expect(response_body["appeals"].size).to eq 0
              expect(response_body["claim_reviews"].size).to eq 2
            end
          end

          context "with invalid Veteran ID" do
            let(:veteran_id) { "invalidID" }

            it "should return a 404" do
              get :show_case_list, params: options
              expect(response.status).to eq 404
            end
          end

          context "and does not have access to the file" do
            let!(:veteran_id) { appeal.veteran.id }

            it "responds with an error" do
              Fakes::BGSService.inaccessible_appeal_vbms_ids = [appeal.veteran_file_number]

              get :show_case_list, params: options
              response_body = JSON.parse(response.body)

              expect(response_body["errors"][0]["title"]).to eq "Access to Veteran file prohibited"
            end
          end
        end
      end
    end

    context "AMA Appeal" do
      context "VSO employee and valid veteran ID" do
        it "returns appeals and claim_reviews" do
          appeal = create(:appeal, claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
          create(:higher_level_review, veteran_file_number: appeal.veteran_file_number)
          create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)
          vso_user = create(:user, :vso_role, css_id: "BVA_VSO")
          User.authenticate!(user: vso_user)

          get :show_case_list, params: { caseflow_veteran_id: appeal.veteran.id, format: :json }
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 200
          expect(response_body["appeals"].size).to eq 1
          expect(response_body["appeals"].first["type"]).to eq "appeal"
          expect(response_body["claim_reviews"].size).to eq 2
        end
      end
    end
  end

  describe "GET appeals/:id" do
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "0000000000S")) }
    let(:request_params) { { appeal_id: appeal.vacols_id } }

    subject { get(:show, params: request_params, format: :json) }

    before { User.authenticate!(roles: ["System Admin"]) }

    context "when user has high enough BGS sensitivity level to access the Veteran's case" do
      it "returns a successful response" do
        subject
        assert_response(:success)
      end
    end

    context "when user does not have high enough BGS sensitivity level to access the Veteran's case" do
      before { allow_any_instance_of(BGSService).to receive(:can_access?).and_return(false) }

      it "returns an error but does not send a message to Sentry" do
        expect(Raven).to receive(:capture_exception).exactly(0).times
        subject
        expect(response.response_code).to eq(403)
      end
    end
  end

  describe "GET appeals/:id.json" do
    it "should succeed" do
      appeal = create_legacy_appeal_with_hearings

      User.authenticate!(roles: ["System Admin"])
      get :show, params: { appeal_id: appeal.vacols_id }, as: :json

      appeal_json = JSON.parse(response.body)["appeal"]["attributes"]

      assert_response :success
      expect(appeal_json["available_hearing_locations"][0]["city"]).to eq "Holdrege"
      expect(appeal_json["hearings"][0]["type"]).to eq "Video"
    end
  end
end
