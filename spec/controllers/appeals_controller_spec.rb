RSpec.describe AppealsController, type: :controller do
  before { User.authenticate!(roles: ["System Admin"]) }

  describe "GET appeals" do
    let(:ssn) { Generators::Random.unique_ssn }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "#{ssn}S")) }
    let(:options) { { format: :json } }
    let(:veteran_id) { appeal.sanitized_vbms_id }

    context "when request header does not contain Veteran ID" do
      it "response should error" do
        get :index, params: options
        expect(response.status).to eq 400
      end
    end

    context "when request header contains Veteran ID with associated appeals" do
      before { request.headers["HTTP_VETERAN_ID"] = veteran_id }

      it "returns valid response with one appeal" do
        get :index, params: options
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["appeals"].size).to eq 1
      end
    end

    context "when request header contains Veteran ID with no associated appeals" do
      before { request.headers["HTTP_VETERAN_ID"] = "#{Generators::Random.unique_ssn}S" }

      it "returns valid response with empty appeals array" do
        get :index, params: options
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["appeals"].size).to eq 0
      end
    end
  end

  describe "GET appeals/appeal_id/document_count" do
    context "when a legacy appeal has documents" do
      let(:documents) do
        [
          create(:document, type: "SSOC", received_at: 6.days.ago),
          create(:document, type: "SSOC", received_at: 7.days.ago)
        ]
      end
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfkey: "654321", documents: documents)) }

      it "should return document count" do
        documents.each { |document| document.update(file_number: appeal.sanitized_vbms_id) }
        get :document_count, params: { appeal_id: appeal.vacols_id }

        response_body = JSON.parse(response.body)
        expect(response_body["document_count"]).to eq 2
      end
    end

    context "when an ama appeal has documents" do
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
  end

  describe "GET cases/:id" do
    let(:the_case) { FactoryBot.create(:case) }
    let!(:appeal) { FactoryBot.create(:legacy_appeal, :with_veteran, vacols_case: the_case) }
    let!(:higher_level_review) { create(:higher_level_review, veteran_file_number: appeal.veteran_file_number) }
    let!(:supplemental_claim) { create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number) }
    let(:options) { { caseflow_veteran_id: veteran_id, format: request_format } }

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
          expect(response.status).to eq 404
        end
      end
    end

    context "when requesting json response" do
    end
  end

  describe "GET appeals/:id" do
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "0000000000S")) }

    it "should succeed" do
      get :show, params: { appeal_id: appeal.vacols_id }

      assert_response :success
    end
  end

  describe "GET appeals/:id.json" do
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "0000000000S")) }

    it "should succeed" do
      get :show, params: { appeal_id: appeal.vacols_id }, as: :json

      assert_response :success
    end
  end
end
