# frozen_string_literal: true

RSpec.describe AppealsController, :all_dbs, type: :controller do
  include TaskHelpers

  describe "GET appeals/:id/edit" do
    let(:ssn) { Generators::Random.unique_ssn }
    let(:options) { { format: :html, appeal_id: appeal_url_identifier } }
    let(:appeal_url_identifier) { appeal.is_a?(LegacyAppeal) ? appeal.vacols_id : appeal.uuid }

    subject { get :edit, params: options }

    before { User.authenticate!(roles: ["System Admin"]) }

    context "AMA appeal" do
      let(:appeal) { create(:appeal, veteran_file_number: ssn) }

      it "returns 200" do
        subject

        expect(response).to be_successful
      end
    end

    context "Legacy Appeal" do
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "#{ssn}S")) }

      it "returns 404" do
        subject

        expect(response).to be_not_found
      end
    end
  end

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
        let!(:veteran_for_appeal) { create(:veteran, file_number: veteran_id) }

        it "returns valid response with one appeal" do
          create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)
          request.headers["HTTP_CASE_SEARCH"] = veteran_id
          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 200
          expect(response_body["appeals"].size).to eq 1
          expect(response_body["claim_reviews"].size).to eq 1
        end
      end

      context "when request header contains Veteran file number but appeal is associated with veteran ssn" do
        let!(:veteran) { create(:veteran, file_number: "000000000", ssn: ssn) }

        it "returns valid response with one appeal" do
          appeal
          request.headers["HTTP_CASE_SEARCH"] = veteran.file_number
          get :index, params: options
          response_body = JSON.parse(response.body)
          expect(response.status).to eq 200
          expect(response_body["appeals"].size).to eq 1
        end
      end

      context "when request header contains existing Veteran ID with no associated appeals" do
        let!(:veteran_without_associated_appeals) { create(:veteran) }

        it "returns valid response with empty appeals array" do
          request.headers["HTTP_CASE_SEARCH"] = veteran_without_associated_appeals.file_number
          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 200
          expect(response_body["appeals"].size).to eq 0
          expect(response_body["claim_reviews"].size).to eq 0
        end
      end

      context "when request header contains existing Veteran ID that maps to multiple veterans" do
        let(:participant_id) { "987654" }
        let!(:veteran_file_number_match) do
          create(:veteran, file_number: ssn, ssn: ssn, participant_id: participant_id)
        end
        let!(:veteran_bgs_match) do
          create(:veteran, file_number: "12345678", ssn: ssn, participant_id: participant_id)
        end
        let!(:appeal) { create(:appeal, veteran_file_number: ssn) }

        before do
          allow_any_instance_of(BGSService).to receive(:fetch_file_number_by_ssn).and_return(nil)

          allow_any_instance_of(BGSService).to receive(:fetch_file_number_by_ssn)
            .with(ssn.to_s)
            .and_return(veteran_bgs_match.file_number)
        end

        it "returns appeals for veteran with appeals" do
          request.headers["HTTP_CASE_SEARCH"] = ssn
          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 200
          expect(response_body["appeals"].size).to eq 1
          expect(response_body["appeals"][0]["attributes"]["veteran_file_number"]).to eq ssn.to_s
          expect(response_body["claim_reviews"].size).to eq 0
        end

        it "returns claims for all veteran records with claims" do
          create(:supplemental_claim, veteran_file_number: veteran_file_number_match.file_number)
          create(:supplemental_claim, veteran_file_number: veteran_bgs_match.file_number)

          request.headers["HTTP_CASE_SEARCH"] = ssn
          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 200
          expect(response_body["claim_reviews"].size).to eq 2
        end

        it "returns ssn match appeals if given file number" do
          request.headers["HTTP_CASE_SEARCH"] = veteran_bgs_match.file_number
          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 200
          expect(response_body["appeals"].size).to eq 1
          expect(response_body["appeals"][0]["attributes"]["veteran_file_number"]).to eq ssn.to_s
        end
      end

      context "with invalid Veteran file number" do
        it "returns valid response with empty appeals array" do
          request.headers["HTTP_CASE_SEARCH"] = "invalid_file_number"
          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 200
          expect(response_body["appeals"].size).to eq 0
          expect(response_body["claim_reviews"].size).to eq 0
        end
      end
    end

    context "when the current user is a VSO employee" do
      let(:vso_user) { create(:user, :vso_role, css_id: "BVA_VSO") }
      let!(:veteran) { create(:veteran, file_number: veteran_id) }

      before do
        User.authenticate!(user: vso_user)
      end

      after do
        BGSService.new.bust_can_access_cache(vso_user, appeal.veteran_file_number)
      end

      context "and does not have access to the file" do
        it "responds with an error" do
          request.headers["HTTP_CASE_SEARCH"] = veteran_id
          Fakes::BGSService.inaccessible_appeal_vbms_ids = [appeal.veteran_file_number]

          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response_body["errors"][0]["title"]).to eq "Access to Veteran file prohibited"
        end
      end

      context "veteran does not exist and VSO employee does not have access to the file" do
        it "responds with an error" do
          request.headers["HTTP_CASE_SEARCH"] = "123"
          Fakes::BGSService.inaccessible_appeal_vbms_ids = [appeal.veteran_file_number, "123"]

          expect_any_instance_of(Fakes::BGSService).to_not receive(:fetch_poas_by_participant_id)

          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response_body["errors"][0]["title"]).to eq "Veteran not found"
        end
      end

      context "and has access to the file" do
        let!(:veteran) { create(:veteran) }
        let(:appeal) do
          create(:appeal,
                 veteran_file_number: veteran.file_number,
                 claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
        end

        it "responds with appeals and claim reviews" do
          create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)

          request.headers["HTTP_CASE_SEARCH"] = appeal.veteran_file_number
          get :index, params: options
          response_body = JSON.parse(response.body)

          expect(response_body["appeals"].size).to eq 1
          expect(response_body["claim_reviews"].size).to eq 1
        end
      end

      context "when request header contains nonexistent Veteran file number" do
        it "returns 404 error", skip: "flake" do
          appeal = create(:appeal, claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
          create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)

          request.headers["HTTP_CASE_SEARCH"] = "123"

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
          veteran_without_associated_appeals = create(:veteran)
          request.headers["HTTP_CASE_SEARCH"] = veteran_without_associated_appeals.file_number

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
      let(:the_case) { create(:case) }
      let(:file_number) { appeal.veteran_file_number }
      let!(:appeal) { create(:legacy_appeal, :with_veteran, vacols_case: the_case) }
      let!(:higher_level_review) { create(:higher_level_review, veteran_file_number: file_number) }
      let!(:supplemental_claim) { create(:supplemental_claim, veteran_file_number: file_number) }
      let(:options) { { veteran_ids: veteran_id, format: request_format } }
      let(:veteran) { Veteran.find_by_file_number(file_number) }

      context "when current user is a System Admin" do
        before { User.authenticate!(roles: ["System Admin"]) }

        context "when requesting html response" do
          let(:request_format) { :html }

          context "with valid Veteran ID" do
            let(:veteran_id) { veteran.id }

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
            let(:veteran_id) { veteran.id }

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
        let(:vso_user) { create(:user, :vso_role) }

        before do
          User.authenticate!(user: vso_user, roles: ["VSO"])
        end

        after do
          BGSService.new.bust_can_access_cache(vso_user, veteran_id)
        end

        context "when requesting json response" do
          let(:request_format) { :json }

          context "with valid Veteran ID" do
            let(:veteran_id) { veteran.id }

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
            let(:veteran_id) { appeal.veteran.id }

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

          get :show_case_list, params: { veteran_ids: appeal.veteran.id, format: :json }
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
    let!(:user) { User.authenticate!(roles: ["System Admin"]) }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "0000000000S")) }
    let!(:veteran) { create(:veteran, file_number: appeal.sanitized_vbms_id) }
    let(:request_params) { { appeal_id: appeal.vacols_id } }

    subject { get(:show, params: request_params, format: :json) }

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

      context "when the user represents the claimant" do
        let!(:user) { User.authenticate!(roles: ["VSO"]) }
        let!(:vso) { create(:vso, participant_id: appeal.claimant[:representative][:participant_id]) }

        before do
          allow_any_instance_of(LegacyAppeal).to receive(:appellant_is_not_veteran).and_return(true)
          allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_id)
            .and_return([appeal.claimant[:representative]])
        end

        it "returns an error but does not send a message to Sentry" do
          expect(Raven).to receive(:capture_exception).exactly(0).times
          subject
          expect(response.response_code).to eq(403)
        end

        context "when feature is enabled" do
          before { FeatureToggle.enable!(:vso_claimant_representative) }
          after { FeatureToggle.disable!(:vso_claimant_representative) }

          it "returns a successful response" do
            subject
            assert_response(:success)
          end
        end
      end
    end
  end

  describe "GET appeals/:id.json" do
    let(:appeal) { create_legacy_appeal_with_hearings }
    let!(:user) { User.authenticate!(roles: ["System Admin"]) }

    subject { get :show, params: { appeal_id: appeal.vacols_id }, as: :json }

    it "should succeed" do
      subject
      appeal_json = JSON.parse(response.body)["appeal"]["attributes"]

      assert_response :success
      expect(appeal_json["available_hearing_locations"][0]["city"]).to eq "Holdrege"
      expect(appeal_json["hearings"][0]["type"]).to eq "Video"
    end

    it "should create an appeal view for the user if it does not exist" do
      expect(appeal.appeal_views.where(user: user).count).to eq 0
      subject
      expect(appeal.appeal_views.where(user: user).count).to eq 1
      subject
      expect(appeal.appeal_views.where(user: user).count).to eq 1
    end
  end

  describe "GET veteran/:appeal_id" do
    let(:veteran_first_name) { "Test" }
    let(:veteran_last_name) { "User" }
    let(:veteran_file_number) { "0000000000" }
    let(:correspondent) { create(:correspondent, snamef: veteran_first_name, snamel: veteran_last_name) }
    let(:appeal) do
      create(
        :legacy_appeal,
        vacols_case: create(
          :case,
          bfcorlid: "#{veteran_file_number}S",
          correspondent: correspondent
        )
      )
    end
    let!(:veteran) do
      create(
        :veteran,
        first_name: veteran_first_name,
        last_name: veteran_last_name,
        file_number: veteran_file_number,
        email_address: "test@test.com"
      )
    end

    before do
      User.authenticate!(roles: ["System Admin"])
    end

    context "when current user is a System Admin" do
      subject do
        get :veteran, params: { appeal_id: appeal.vacols_id }, as: :json
        response
      end

      it "returns expected response", :aggregate_failures do
        expect(subject.status).to eq 200
        expect(JSON.parse(subject.body)["veteran"]["email_address"]).to eq "test@test.com"
        expect(JSON.parse(subject.body)["veteran"]["full_name"]).to eq "Test User"
      end
    end
  end

  describe "Get legacy appeal Power of Attorney" do
    let!(:user) { User.authenticate!(roles: ["System Admin"]) }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "0000000000S")) }
    let!(:veteran) { create(:veteran, file_number: appeal.sanitized_vbms_id) }
    let(:get_params) { { appeal_id: appeal.vacols_id } }
    let(:patch_params) { { appeal_id: appeal.vacols_id, poaId: appeal.power_of_attorney.id } }
    let!(:poa) do
      create(
        :bgs_power_of_attorney,
        :with_name_cached,
        appeal: appeal
      )
    end

    context "get the appeals POA information" do
      subject do
        get :power_of_attorney, params: get_params
      end

      it "returns a successful response" do
        subject

        assert_response(:success)
        expect(JSON.parse(subject.body)["representative_type"]).to eq "Attorney"
        expect(JSON.parse(subject.body)["representative_name"]).to eq "Clarence Darrow"
        expect(JSON.parse(subject.body)["representative_email_address"]).to eq "clarence.darrow@caseflow.gov"
        expect(JSON.parse(subject.body)["representative_tz"]).to eq "America/Los_Angeles"
        expect(JSON.parse(subject.body)["representative_id"]).to eq appeal.power_of_attorney.bgs_id
      end
    end

    context do
      subject do
        participant_id = appeal.claimant&.dig(:representative, :participant_id)
        Rails.cache.write("bgs-participant-poa-not-found-#{participant_id}", true)
        patch :update_power_of_attorney, params: patch_params
      end

      it "clears not_found cache when claimant is a hash" do
        expect(appeal.power_of_attorney).to_not eq(nil)
        expect(appeal.claimant.is_a?(Hash)).to eq(true)
        participant_id = appeal.claimant&.dig(:representative, :participant_id)
        expect(Rails.cache.read("bgs-participant-poa-not-found-#{participant_id}")).to eq(nil)
      end
    end
  end

  describe "Get AMA appeal Power of Attorney" do
    let!(:user) { User.authenticate!(roles: ["System Admin"]) }
    let!(:appeal) do
      create(
        :appeal,
        veteran_file_number: "500000102",
        receipt_date: 6.months.ago.to_date.mdY
      )
    end
    let(:patch_params) { { appeal_id: appeal.uuid, poaId: appeal.power_of_attorney.id } }
    let!(:poa) do
      create(
        :bgs_power_of_attorney,
        :with_name_cached,
        appeal: appeal
      )
    end

    context "get the appeals POA information" do
      subject do
        patch :update_power_of_attorney, params: patch_params
      end

      it "returns a successful response" do
        subject

        assert_response(:success)
        expect(JSON.parse(subject.body)["power_of_attorney"]["representative_type"]).to eq "Attorney"
        expect(JSON.parse(subject.body)["power_of_attorney"]["representative_name"]).to eq "Clarence Darrow"
        expected_email = "tom.brady@caseflow.gov"
        expect(JSON.parse(subject.body)["power_of_attorney"]["representative_email_address"]).to eq expected_email
        expect(JSON.parse(subject.body)["power_of_attorney"]["representative_tz"]).to eq "America/Los_Angeles"
        expect(JSON.parse(subject.body)["power_of_attorney"]["representative_id"]).to eq appeal.power_of_attorney.id
      end
    end
  end
end
