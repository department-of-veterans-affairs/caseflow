# frozen_string_literal: true

require "webmock/rspec"

describe Test::LoadTestsController, :postgres, type: :controller do
  let(:css_id) { "VACOUSER" }
  let(:email) { "user@example.com" }
  let!(:user) { create(:user, css_id: css_id, email: email) }

  before do
    User.authenticate!(user: user)
  end

  context "#index" do
    it "accesses load testing page" do
      get :index
      expect(response.status).to eq 200
    end
  end

  context "#target" do
    context "providing target_id" do
      let(:appeal_with_uuid) do
        Appeal.new(veteran_file_number: "1234",
                   uuid: "79166847-1e99-4921-a084-62963d0fc63e")
      end
      let(:legacy_appeal_with_vacols_id) { LegacyAppeal.new(vacols_id: "123") }

      it "gets Appeal target information" do
        appeal_with_uuid.save!
        get :target, params: { target_type: "Appeal", target_id: "79166847-1e99-4921-a084-62963d0fc63e" }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)["data"]).to eq(appeal_with_uuid.uuid)
        get :target, params: { target_type: "Appeal", target_id: "79166847-1e99-4921-a084-incorrectid" }
        expect(response.status).to eq 404
      end

      it "gets LegacyAppeal target information" do
        legacy_appeal_with_vacols_id.save!
        get :target, params: { target_type: "LegacyAppeal", target_id: "123" }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)["data"]).to eq(legacy_appeal_with_vacols_id.vacols_id)
      end
    end

    context "not providing target_id" do
      let(:appeal) { Appeal.new(veteran_file_number: "1234") }
      let(:supplemental_claim) { SupplementalClaim.new(veteran_file_number: "12345") }

      it "gets Appeal target information" do
        appeal.save!
        appeal.reload
        get :target, params: { target_type: "Appeal" }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)["data"]).to eq(appeal.uuid)
      end

      it "gets SupplementalClaim target information" do
        supplemental_claim.save!
        supplemental_claim.reload
        get :target, params: { target_type: "SupplementalClaim" }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)["data"]).to eq(supplemental_claim.uuid)
      end
    end
  end

  context "#run_load_tests" do
    before do
      # Set ENV variables
      ENV["JENKINS_CRUMB_ISSUER_URI"] = "http://testJenkinsPipeline.com/crumbIssuer/api/json"
      ENV["LOAD_TESTING_PIPELINE_URI"] = "http://testJenkinsPipeline.com/job/loadTestPipeline/buildWithParameters"
      ENV["LOAD_TESTING_PIPELINE_TOKEN"] = "testPipelineToken"
    end

    let(:response_headers_hash) do
      { "date" => ["Tue, 01 Oct 2024 21:18:29 GMT"],
        "connection" => ["close"],
        "x-content-type-options" => ["nosniff"],
        "x-jenkins" => ["2.440.1"],
        "x-jenkins-session" => ["50a9f26c"],
        "x-frame-options" => ["deny"],
        "content-type" => ["application/json;charset=utf-8"],
        "set-cookie" =>
      ["JSESSIONID.012=node012; Path=/; HttpOnly"],
        "expires" => ["Thu, 01 Jan 1970 00:00:00 GMT"],
        "server" => ["Jetty(10.0.18)"] }
    end

    let(:scenarios) do
      { "scenarios": [{
        "appealVeteranTest": {
          "targetType": "LegacyAppeal",
          "targetId": "3436456"
        }
      }] }
    end

    context "with an unsuccessful crumbIssuer response" do
      it "raises an appropriate error" do
        stub_request(:get, ENV["JENKINS_CRUMB_ISSUER_URI"])\
          .with(query: "token=#{ENV['LOAD_TESTING_PIPELINE_TOKEN']}")\
          .to_return(status: 404, headers: response_headers_hash, body: "Test Error")

        get :run_load_tests, params: { data: scenarios }

        expect(response.status).to eq 200
        expect(response.body).to include("Crumb Response: Test Error")
      end
    end

    context "with a successful crumbIssuer response" do
      let(:jenkins_request_headers_hash) do
        { "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Cookie" => "JSESSIONID.012=node012; Path=/; HttpOnly",
          "Host" => "testJenkinsPipeline.com",
          "Jenkins-Crumb" => "value",
          "User-Agent" => "Ruby" }
      end

      let(:form_data) { ActionController::Parameters.new(data: scenarios) }
      let(:test_recipe) { Base64.encode64(form_data[:data].to_s) }

      before do
        crumb = "{\"_class\":\"hudson.security.csrf.DefaultCrumbIssuer\","\
        "\"crumb\":\"value\",\"crumbRequestField\":\"Jenkins-Crumb\"}"

        stub_request(:get, ENV["JENKINS_CRUMB_ISSUER_URI"])
          .with(query: "token=#{ENV['LOAD_TESTING_PIPELINE_TOKEN']}")
          .to_return(body: crumb, status: 200, headers: response_headers_hash)
      end

      it "sends a request to Jenkins successfully create a load test run" do
        stub_request(:post, ENV["LOAD_TESTING_PIPELINE_URI"])
          .with(
            body: test_recipe,
            headers: jenkins_request_headers_hash,
            query: "token=#{ENV['LOAD_TESTING_PIPELINE_TOKEN']}"
          )
          .to_return(status: 201, body: "", headers: {})

        get :run_load_tests, params: { data: scenarios }

        expect(response.status).to eq 200
        expect(response.body).to include("201")
      end

      it "sends a request to Jenkins which is unsuccessful in creating a load test run" do
        stub_request(:post, ENV["LOAD_TESTING_PIPELINE_URI"])
          .with(
            body: test_recipe,
            headers: jenkins_request_headers_hash,
            query: "token=#{ENV['LOAD_TESTING_PIPELINE_TOKEN']}"
          )
          .to_return(status: 404, body: "Test Error", headers: {})

        get :run_load_tests, params: { data: scenarios }

        expect(response.status).to eq 200
        expect(response.body).to include("Jenkins Response: Test Error")
      end
    end
  end
end
