RSpec.describe AppealsController, type: :controller do
  before { User.authenticate!(roles: ["System Admin"]) }

  describe "GET appeals" do
    let(:ssn) { Generators::Random.unique_ssn }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "#{ssn}S")) }
    let(:veteran_id) { appeal.vbms_id }

    context "when request header does not contain Veteran ID" do
      it "response should error" do
        get :index
        expect(response.status).to eq 400
      end
    end

    context "when request header contains Veteran ID with associated appeals" do
      before { request.headers["HTTP_VETERAN_ID"] = veteran_id }

      it "returns valid response with one appeal" do
        get :index
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["appeals"].size).to eq 1
      end
    end

    context "when request header contains Veteran ID with no associated appeals" do
      before { request.headers["HTTP_VETERAN_ID"] = "#{Generators::Random.unique_ssn}S" }

      it "returns valid response with empty appeals array" do
        get :index
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["appeals"].size).to eq 0
      end
    end
  end

  describe "GET appeals/appeal_id/document_count" do
    context "when appeal has documents" do
      let(:documents) do
        [
          Document.new(type: "SSOC", received_at: 6.days.ago),
          Document.new(type: "SSOC", received_at: 7.days.ago)
        ]
      end
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfkey: "654321", documents: documents)) }

      it "should return document count" do
        get :document_count, params: { appeal_id: appeal.vacols_id }

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
    let(:ssn) { Generators::Random.unique_ssn }
    let(:appeal) { create(:legacy_appeal, :with_veteran, vacols_case: create(:case, bfcorlid: "#{ssn}S")) }
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
