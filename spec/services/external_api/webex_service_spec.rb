# frozen_string_literal: true

describe ExternalApi::WebexService do
  let(:host) { "fake-broker." }
  let(:port) { "0000" }
  let(:aud) { "1234abcd" }
  let(:apikey) { SecureRandom.uuid.to_s }
  let(:domain) { "gov.fake.com" }
  let(:api_endpoint) { "/api/v2/fake" }
  let(:query) { nil }

  let(:webex_service) do
    ExternalApi::WebexService.new(
      host: host,
      domain: domain,
      api_endpoint: api_endpoint,
      aud: aud,
      apikey: apikey,
      port: port,
      query: query
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

      let(:method) { "POST" }

      subject { webex_service.create_conference(virtual_hearing) }

      it "calls send_webex_request and passes the correct body" do
        expect(webex_service).to receive(:send_webex_request).with(body, method)
        subject
      end

      it "returns a successful instance of CreateResponse class" do
        allow(webex_service).to receive(:send_webex_request).with(body, method).and_return(success_create_resp)

        expect(subject).to be_instance_of(ExternalApi::WebexService::CreateResponse)
        expect(subject.code).to eq(200)
        expect(subject.success?).to eq(true)
      end

      it "returns error response" do
        allow(webex_service).to receive(:send_webex_request).with(body, method).and_return(error_create_resp)

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

      let(:method) { "POST" }
      subject { webex_service.delete_conference(virtual_hearing) }

      it "calls send_webex_request and passes correct body" do
        expect(webex_service).to receive(:send_webex_request).with(body, method)
        subject
      end

      it "returns a successful instance of CreateResponse class" do
        allow(webex_service).to receive(:send_webex_request).with(body, method).and_return(success_create_resp)

        expect(subject).to be_instance_of(ExternalApi::WebexService::DeleteResponse)
        expect(subject.code).to eq(200)
        expect(subject.success?).to eq(true)
      end

      it "returns error response" do
        allow(webex_service).to receive(:send_webex_request).with(body, method).and_return(error_create_resp)

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

    describe "get recordings list" do
      let(:query) do
        from = CGI.escape(2.days.ago.in_time_zone("America/New_York").end_of_day.iso8601)
        to = CGI.escape(1.day.ago.in_time_zone("America/New_York").end_of_day.iso8601)
        { "from": from, "to": to }
      end

      let(:success_recordings_resp) do
        HTTPI::Response.new(200, {}, {})
      end

      let(:error_recordings_resp) do
        HTTPI::Response.new(400, {}, {})
      end

      let(:body) { nil }

      let(:method) { "GET" }

      subject { webex_service.get_recordings_list }

      it "it calls send webex request with nil body and GET method" do
        expect(webex_service).to receive(:send_webex_request).with(body, method)
        subject
      end

      it "returns a successful instance of RecordingsListResponse class" do
        allow(webex_service).to receive(:send_webex_request).with(body, method).and_return(success_create_resp)

        expect(subject).to be_instance_of(ExternalApi::WebexService::RecordingsListResponse)
        expect(subject.code).to eq(200)
        expect(subject.success?).to eq(true)
      end

      it "returns recordings error response" do
        allow(webex_service).to receive(:send_webex_request).with(body, method).and_return(error_create_resp)

        expect(subject.code).to eq(400)
        expect(subject.success?).to eq(false)
        expect(subject.error).to eq(Caseflow::Error::WebexBadRequestError.new(code: 400))
      end

      describe "with fakes" do
        let(:webex_service) do
          Fakes::WebexService.new
        end

        it "gets a list of ids" do
          expect(subject.code).to eq(200)
          expect(subject.ids).to eq(%w[4f914b1dfe3c4d11a61730f18c0f5387 3324fb76946249cfa07fc30b3ccbf580 42b80117a2a74dcf9863bf06264f8075])
          subject
        end
      end
    end

    describe "get recording details" do
      let(:query) do
        id = "4f914b1dfe3c4d11a61730f18c0f5387"
        { "id": id }
      end

      let(:success_details_resp) do
        HTTPI::Response.new(200, {}, {})
      end

      let(:error_details_resp) do
        HTTPI::Response.new(400, {}, {})
      end

      let(:body) { nil }

      let(:method) { "GET" }

      subject { webex_service.get_recording_details }

      it "it calls send webex request with nil body and GET method" do
        expect(webex_service).to receive(:send_webex_request).with(body, method)
        subject
      end

      it "returns a successful instance of RecordingDetailsResponse class" do
        allow(webex_service).to receive(:send_webex_request).with(body, method).and_return(success_create_resp)

        expect(subject).to be_instance_of(ExternalApi::WebexService::RecordingDetailsResponse)
        expect(subject.code).to eq(200)
        expect(subject.success?).to eq(true)
      end

      it "returns recording details error response" do
        allow(webex_service).to receive(:send_webex_request).with(body, method).and_return(error_create_resp)

        expect(subject.code).to eq(400)
        expect(subject.success?).to eq(false)
        expect(subject.error).to eq(Caseflow::Error::WebexBadRequestError.new(code: 400))
      end

      describe "with fakes" do
        let(:webex_service) do
          Fakes::WebexService.new
        end

        it "gets a list of ids" do
          expect(subject.code).to eq(200)
          expect(subject.mp4_link).to eq("https://site4-example.webex.com/nbr/MultiThreadDownloadServlet?siteid=2062842&recordid=305462&confid=137735449369118342&language=en_US&userid=3516472&serviceRecordID=305492&ticket=SDJTSwAAAIUBSHkvL6Z5ddyBim5%2FHcJYcvn6IoXNEyCE2mAYQ5BlBg%3D%3D&timestamp=1567125236465&islogin=yes&isprevent=no&ispwd=yes")
          expect(subject.vtt_link).to eq("https://site4-example.webex.com/nbr/downloadMedia.do?siteid=2062842&recordid=305462&confid=137735449369118342&language=en_US&userid=3516472&serviceRecordID=305492&ticket=SDJTSwAAAAJVUJDxeA08qKkF%2FlxlSkDxuEFPwgGT0XW1z21NhY%2BCvg%3D%3D&timestamp=1567125236866&islogin=yes&isprevent=no&ispwd=yes&mediaType=2")
          expect(subject.mp3_link).to eq("https://site4-example.webex.com/nbr/downloadMedia.do?siteid=2062842&recordid=305462&confid=137735449369118342&language=en_US&userid=3516472&serviceRecordID=305492&ticket=SDJTSwAAAIXCIXsuBt%2BAgtK7WoQ2VhgeI608N4ZMIJ3vxQaQNZuLZA%3D%3D&timestamp=1567125236708&islogin=yes&isprevent=no&ispwd=yes&mediaType=1")
          subject
        end
      end
    end
  end
end
