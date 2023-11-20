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
            "nbf": virtual_hearing.hearing.scheduled_for.beginning_of_day.to_i,
            "exp": virtual_hearing.hearing.scheduled_for.end_of_day.to_i
          },
          "aud": aud,
          "numHost": 1,
          "provideShortUrls": true,
          "verticalType": "gen"
        }
      end

      subject { webex_service.create_conference(virtual_hearing) }

      it "calls send_webex_request and passes the correct body" do
        expect(webex_service).to receive(:send_webex_request).with(body)
        subject
      end

      it "returns a successful instance of CreateResponse class" do
        allow(webex_service).to receive(:send_webex_request).with(body).and_return(success_create_resp)

        expect(subject).to be_instance_of(ExternalApi::WebexService::CreateResponse)
        expect(subject.code).to eq(200)
        expect(subject.success?).to eq(true)
      end

      it "returns error response" do
        allow(webex_service).to receive(:send_webex_request).with(body).and_return(error_create_resp)

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
          expect(JSON.parse(subject.resp.body)["baseUrl"]).to eq("https://instant-usgov.webex.com/visit/")
          subject
        end
      end
    end

    describe "delete conference" do
      let(:body) do
        {
          "jwt": {
            "sub": virtual_hearing.subject_for_conference,
            "nbf": 0,
            "exp": 0
          },
          "aud": aud,
          "numHost": 1,
          "provideShortUrls": true,
          "verticalType": "gen"
        }
      end
      subject { webex_service.delete_conference(virtual_hearing) }

      it "calls send_webex_request and passes correct body" do
        expect(webex_service).to receive(:send_webex_request).with(body)
        subject
      end

      it "returns a successful instance of CreateResponse class" do
        allow(webex_service).to receive(:send_webex_request).with(body).and_return(success_create_resp)

        expect(subject).to be_instance_of(ExternalApi::WebexService::DeleteResponse)
        expect(subject.code).to eq(200)
        expect(subject.success?).to eq(true)
      end

      it "returns error response" do
        allow(webex_service).to receive(:send_webex_request).with(body).and_return(error_create_resp)

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
          expect(JSON.parse(subject.resp.body)["baseUrl"]).to eq("https://instant-usgov.webex.com/visit/")
          subject
        end
      end
    end
  end
end
