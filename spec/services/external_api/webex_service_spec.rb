# frozen_string_literal: true

describe ExternalApi::WebexService do
  before do
    subject { ExternalApi::WebexService.new }
    stub_const("ENV", "WEBEX_HOST" => "fake.api")
    stub_const("ENV", "WEBEX_DOMAIN" => ".webex.com")
    stub_const("ENV", "WEBEX_CLIENT_ID" => "fake_id")
    stub_const("ENV", "WEBEX_CLIENT_SECRET" => "fake_secret")
    stub_const("ENV", "WEBEX_REFRESH_TOKEN" => "fake_token")
  end

  describe "OAuth" do
    let(:example_auth_response_body) do
      { "access_token": "fake_token",
        "refresh_token": "fake_token",
        "expires_in": "99999999",
        "refresh_token_expires_in": "99999999" }
    end
    header = { "Content-Type": "application/x-www-form-urlencoded", Accept: "application/json" }
    let(:example_auth_response) { HTTPI::Response.new(200, header, example_auth_response_body.to_json) }
    let(:caseflow_auth_response) { ExternalApi::WebexService::Response.new(example_auth_response) }
    it "refreshes access token" do
      allow(Faraday).to receive(:post).and_return(example_auth_response)
      expect(subject.refresh_access_token).to eq(caseflow_auth_response.resp)
    end
  end

  context "error" do
    let(:example_expired_refresh_token_response) do
      { "error": "invalid_token",
        "error_description": "The access token expired" }
    end
    header = { "Content-Type": "application/x-www-form-urlencoded", Accept: "application/json" }
    let(:example_401_response) { HTTPI::Response.new(401, header, example_expired_refresh_token_response.to_json) }
    let(:caseflow_401_response) { ExternalApi::WebexService::Response.new(example_401_response) }
    it "returns an invalid token error" do
      allow(Faraday).to receive(:post).and_return(example_401_response)
      expect { subject.refresh_access_token }.to raise_error(Caseflow::Error::WebexInvalidTokenError)
    end
    let(:host) { "fake-broker." }
    let(:port) { "0000" }
    let(:aud) { "1234abcd" }
    let(:apikey) { SecureRandom.uuid.to_s }
    let(:domain) { "gov.fake.com" }
    let(:api_endpoint) { "/api/v2/fake" }

    let(:webex_service) do
      ExternalApi::WebexService.new(
        host: host,
        domain: domain,
        api_endpoint: api_endpoint,
        aud: aud,
        apikey: apikey,
        port: port
      )
    end
  end

  describe "webex requests" do
    let(:virtual_hearing) do
      create(:virtual_hearing)
    end

    let(:success_create_resp) do
      HTTPI::Response.new(200, {}, {})
    end

    let(:error_create_resp) do
      HTTPI::Response.new(400, {}, {})
    end

    describe "create conference" do
      let(:body) do
        {
          "jwt": {
            "sub": virtual_hearing.subject_for_conference,
            "Nbf": virtual_hearing.hearing.scheduled_for.beginning_of_day.to_i,
            "Exp": virtual_hearing.hearing.scheduled_for.end_of_day.to_i
          },
          "aud": aud,
          "numGuest": 1,
          "numHost": 1,
          "provideShortUrls": true
        }
      end

      subject { webex_service.create_conference(virtual_hearing) }

      it "calls send_webex_request and passes the correct body" do
        expect(webex_service).to receive(:send_webex_request).with(body: body)
        subject
      end

      it "returns a successful instance of CreateResponse class" do
        allow(webex_service).to receive(:send_webex_request).with(body: body).and_return(success_create_resp)

        expect(subject).to be_instance_of(ExternalApi::WebexService::CreateResponse)
        expect(subject.code).to eq(200)
        expect(subject.success?).to eq(true)
      end

      it "returns error response" do
        allow(webex_service).to receive(:send_webex_request).with(body: body).and_return(error_create_resp)

        expect(subject.code).to eq(400)
        expect(subject.success?).to eq(false)
        expect(subject.error).to eq(Caseflow::Error::WebexBadRequestError.new(code: 400))
      end

      describe "with fakes" do
        let(:webex_service) do
          Fakes::WebexService.new
        end

        it "creates a conference" do
          expect(subject.code).to eq(200)
          expect(subject.resp.body[:baseUrl]).to eq("https://instant-usgov.webex.com/visit/")
          subject
        end
      end
    end

    describe "delete conference" do
      let(:body) do
        {
          "jwt": {
            "sub": virtual_hearing.subject_for_conference,
            "Nbf": 0,
            "Exp": 0
          },
          "aud": aud,
          "numGuest": 1,
          "numHost": 1,
          "provideShortUrls": true
        }
      end
      subject { webex_service.delete_conference(virtual_hearing) }

      it "calls send_webex_request and passes correct body" do
        expect(webex_service).to receive(:send_webex_request).with(body: body)
        subject
      end

      it "returns a successful instance of CreateResponse class" do
        allow(webex_service).to receive(:send_webex_request).with(body: body).and_return(success_create_resp)

        expect(subject).to be_instance_of(ExternalApi::WebexService::DeleteResponse)
        expect(subject.code).to eq(200)
        expect(subject.success?).to eq(true)
      end

      it "returns error response" do
        allow(webex_service).to receive(:send_webex_request).with(body: body).and_return(error_create_resp)

        expect(subject.code).to eq(400)
        expect(subject.success?).to eq(false)
        expect(subject.error).to eq(Caseflow::Error::WebexBadRequestError.new(code: 400))
      end

      describe "with fakes" do
        let(:webex_service) do
          Fakes::WebexService.new
        end

        it "deletes a conference" do
          expect(subject.code).to eq(200)
          expect(subject.resp.body[:baseUrl]).to eq("https://instant-usgov.webex.com/visit/")
          subject
        end
      end
    end
  end
end
