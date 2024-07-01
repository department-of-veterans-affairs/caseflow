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
  let(:success_response) do
    HTTPI::Response.new(200, {}, {})
  end
  let(:error_response) do
    HTTPI::Response.new(400, {}, {})
  end

  describe "webex requests" do
    let(:virtual_hearing) do
      create(:virtual_hearing)
    end

    shared_examples "calls webex service and returns appropriate success and error respones" do
      it "calls send_webex_request and passes the correct body" do
        allow(webex_service).to receive(:send_webex_request).with(body, method).and_return(success_response)
        expect(webex_service).to receive(:send_webex_request).with(body, method)
        subject
      end

      it "returns a successful instance of CreateResponse class" do
        allow(webex_service).to receive(:send_webex_request).with(body, method).and_return(success_response)

        expect(subject).to be_instance_of(response_type)
        expect(subject.code).to eq(200)
        expect(subject.success?).to eq(true)
      end

      it "returns error response" do
        allow(webex_service).to receive(:send_webex_request).with(body, method).and_return(error_response)

        expect(subject.code).to eq(400)
        expect(subject.success?).to eq(false)
        expect(subject.error).to eq(Caseflow::Error::WebexBadRequestError.new(code: 400))
      end
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
          "numHost": 2,
          "provideShortUrls": true,
          "verticalType": "gen"
        }
      end
      let(:method) { "POST" }
      let(:response_type) { ExternalApi::WebexService::CreateResponse }

      subject { webex_service.create_conference(virtual_hearing) }

      include_examples "calls webex service and returns appropriate success and error respones"

      context "with fakes" do
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
          "numHost": 2,
          "provideShortUrls": true,
          "verticalType": "gen"
        }
      end
      let(:method) { "POST" }
      let(:response_type) { ExternalApi::WebexService::DeleteResponse }

      subject { webex_service.delete_conference(virtual_hearing) }

      include_examples "calls webex service and returns appropriate success and error respones"

      context "with fakes" do
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
        max = 100
        id = "f91b6edce9864428af084977b7c68291_I_166641849979635652"
        { "max": max, "id": id }
      end
      let(:body) { nil }
      let(:method) { "GET" }
      let(:response_type) { ExternalApi::WebexService::RecordingsListResponse }

      subject { webex_service.fetch_recordings_list }

      include_examples "calls webex service and returns appropriate success and error respones"

      context "with fakes" do
        let(:webex_service) do
          Fakes::WebexService.new
        end

        it "gets a list of recordings objects with associated id and host email" do
          expect(subject.code).to eq(200)
          expect(subject.recordings.first.id).to eq("4f914b1dfe3c4d11a61730f18c0f5387")
          expect(subject.recordings.first.host_email).to eq("john.andersen@example.com")
          expect(subject.recordings.second.id).to eq("3324fb76946249cfa07fc30b3ccbf580")
          expect(subject.recordings.second.host_email).to eq("john.andersen@example.com")
          expect(subject.recordings.third.id).to eq("42b80117a2a74dcf9863bf06264f8075")
          expect(subject.recordings.third.host_email).to eq("john.andersen@example.com")
          subject
        end
      end
    end

    describe "get recording details" do
      let(:query) do
        id = "4f914b1dfe3c4d11a61730f18c0f5387"
        { "id": id }
      end
      let(:body) { nil }
      let(:method) { "GET" }
      let(:recording_id) { "fake_id" }
      let(:response_type) { ExternalApi::WebexService::RecordingDetailsResponse }

      subject { webex_service.fetch_recording_details(recording_id) }

      include_examples "calls webex service and returns appropriate success and error respones"

      context "with fakes" do
        let(:webex_service) do
          Fakes::WebexService.new
        end

        it "gets a list of ids" do
          expect(subject.code).to eq(200)
          expect(subject.mp4_link).to eq("https://www.learningcontainer.com/mp4-sample-video-files-download/#")
          expect(subject.vtt_link).to eq("https://www.capsubservices.com/assets/downloads/web/WebVTT.vtt")
          expect(subject.mp3_link).to eq("https://freetestdata.com/audio-files/mp3/")
          expect(subject.topic).to eq("Webex meeting-20240520 2030-1")
          subject
        end
      end
    end

    describe "get rooms list" do
      let(:body) { nil }
      let(:method) { "GET" }
      let(:response_type) { ExternalApi::WebexService::RoomsListResponse }

      subject { webex_service.fetch_rooms_list }

      include_examples "calls webex service and returns appropriate success and error respones"

      context "with fakes" do
        let(:webex_service) do
          Fakes::WebexService.new
        end
        let(:room_id) do
          "Y2lzY29zcGFyazovL3VybjpURUFNOnVzLWdvdi13ZXN0LTFfYTEvUk9PTS85YTZjZTRjMC0xNmM5LTExZWYtYjIxOC1iMWE5YTQ2"
        end
        let(:room_title) { "Virtual Visit - 221218-977_933_Hearing-20240508 1426" }

        it "gets a list of room objects with ids and titles" do
          expect(subject.code).to eq(200)
          expect(subject.rooms.all?(ExternalApi::WebexService::RoomsListResponse::Room)).to eq(true)
          room = subject.rooms.first
          expect(room.id).to eq(room_id)
          expect(room.title).to eq(room_title)
          subject
        end
      end
    end

    describe "get room details" do
      let(:body) { nil }
      let(:method) { "GET" }
      let(:response_type) { ExternalApi::WebexService::RoomDetailsResponse }
      let(:room_id) { "fake_id" }

      subject { webex_service.fetch_room_details(room_id) }

      include_examples "calls webex service and returns appropriate success and error respones"

      context "with fakes" do
        let(:webex_service) do
          Fakes::WebexService.new
        end
        let(:meeting_id) { "f91b6edce9864428af084977b7c68291_I_166641849979635652" }

        it "get meeting id from room details" do
          expect(subject.code).to eq(200)
          expect(subject.meeting_id).to eq(meeting_id)
          subject
        end
      end
    end
  end
end
