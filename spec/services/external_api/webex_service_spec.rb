# frozen_string_literal: true

describe ExternalApi::WebexService do
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

  let(:virtual_hearing) { create(:virtual_hearing) }
  let(:success_create_resp) { HTTPI::Response.new(200, {}, {}) }
  let(:error_create_resp) { HTTPI::Response.new(400, {}, {}) }

  shared_examples_for "webex request" do |method, response_class|
    subject { webex_service.public_send(method, virtual_hearing) }

    it "calls send_webex_request and passes the correct body" do
      expect(webex_service).to receive(:send_webex_request).with(body: body)
      subject
    end

    it "returns a successful instance of #{response_class} class" do
      allow(webex_service).to receive(:send_webex_request).with(body: body).and_return(success_create_resp)

      expect(subject).to be_instance_of(response_class)
      expect(subject.code).to eq(200)
      expect(subject.success?).to eq(true)
    end

    it "returns error response" do
      allow(webex_service).to receive(:send_webex_request).with(body: body).and_return(error_create_resp)

      expect(subject.code).to eq(400)
      expect(subject.success?).to eq(false)
      expect(subject.error).to eq(Caseflow::Error::WebexBadRequestError.new(code: 400))
    end
  end

  describe "with fakes" do
    let(:webex_service) do
      Fakes::WebexService.new(
        host: host,
        port: port,
        aud: aud,
        apikey: apikey,
        domain: domain,
        api_endpoint: api_endpoint
      )
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
        Fakes::WebexService.new(
          host: host,
          port: port,
          aud: aud,
          apikey: apikey,
          domain: domain,
          api_endpoint: api_endpoint
        )
      end

      it "deletes a conference" do
        expect(subject.code).to eq(200)
        expect(subject.resp.body[:baseUrl]).to eq("https://instant-usgov.webex.com/visit/")
        subject
      end
    end
  end
end
