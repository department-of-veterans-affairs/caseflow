# frozen_string_literal: true

RSpec.describe Api::V2::HearingsController, :all_dbs, type: :controller do
  let(:api_key) { ApiKey.create!(consumer_name: "API Consumer").key_string }

  before(:each) do
    request.headers["Authorization"] = "Token token=#{api_key}"
  end

  describe "GET hearings by hearing day" do
    context "with valid API key" do
      %w[
        invalid
        2019/07/08
        1234578
        2019-1-1
        07-08-2019
        July\ 7,\ 2019
        July\ 7\ 2019
        !@#$
        nil
      ].each do |bad_date|
        it "returns 422 with date \"#{bad_date}\"" do
          get :show, params: { hearing_day: bad_date }
          expect(response.status).to eq 422
        end
      end

      it "returns 404 when no hearings days are found" do
        get :show, params: { hearing_day: "2019-07-07" }
        expect(response.status).to eq 404
      end

      context "response for hearing day but no hearings" do
        let!(:hearing_day) do
          create(:hearing_day, scheduled_for: Date.new(2019, 7, 7))
        end

        subject do
          get :show, params: { hearing_day: "2019-07-07" }
          response
        end

        it "returns expected response", :aggregate_failures do
          expect(subject.status).to eq 200
          expect(JSON.parse(subject.body)).to have_key("hearings")
          expect(JSON.parse(subject.body)["hearings"]).to eq []
        end
      end

      context "response for hearing day with hearings" do
        shared_examples_for "hearings api route that serializes virtual hearing" do
          let!(:virtual_hearing) do
            create(:virtual_hearing, :initialized, hearing: hearings[0])
          end

          it "returns a 200 and has expected response", :aggregate_failures do
            virtual_hearing.activate!
            expect(subject.status).to eq 200
            response_body = JSON.parse(subject.body)
            expect(response_body).to have_key("hearings")
            expect(response_body["hearings"].size).to be >= 1
            expect(response_body["hearings"][0]["is_virtual"]).to eq true
          end
        end

        let(:hearing_day) do
          create(
            :hearing_day,
            request_type: HearingDay::REQUEST_TYPES[:video],
            scheduled_for: Date.new(2019, 7, 7),
            regional_office: "VACO"
          )
        end
        let(:hearing_day_in_hawaii) do
          create(
            :hearing_day,
            request_type: HearingDay::REQUEST_TYPES[:video],
            scheduled_for: Date.new(2019, 7, 7),
            regional_office: "RO59"
          )
        end

        context "ama hearings" do
          let!(:hearings) do
            [
              create(:hearing, regional_office: "VACO", hearing_day: hearing_day, scheduled_time: "9:30AM"),
              create(:hearing, regional_office: "RO59", hearing_day: hearing_day_in_hawaii, scheduled_time: "10:30AM"),
              create(:hearing, regional_office: "RO62", hearing_day: hearing_day_in_hawaii, scheduled_time: "11:30AM")
            ]
          end
          let!(:postponed_hearing) do
            create(
              :hearing,
              regional_office: "VACO",
              hearing_day: hearing_day,
              scheduled_time: "12:30PM",
              disposition: "postponed"
            )
          end

          subject do
            get :show, params: { hearing_day: "2019-07-07" }
            response
          end

          it "returns a 200 and response has expected attributes and values", :aggregate_failures do
            expect(subject.status).to eq 200
            response_body = JSON.parse(subject.body)
            expect(response_body).to have_key("hearings")
            expect(response_body["hearings"].size).to eq 3
            expect(response_body["hearings"][0]["timezone"]).to eq("America/New_York")
            expect(response_body["hearings"][1]["timezone"]).to eq("Pacific/Honolulu")
            expect(response_body["hearings"][2]["timezone"]).to eq("America/Chicago")
            expect(response_body["hearings"][0]["is_virtual"]).to eq(false)

            first_location = response_body["hearings"][0]["hearing_location"]
            expect(first_location).to eq("Board of Veterans' Appeals CO Office")

            expected_times = hearings.map(&:scheduled_for)
            scheduled_times = response_body["hearings"].map { |hearing| hearing["scheduled_for"] }

            expect(scheduled_times).to match_array(expected_times)
            expected_participant_ids = hearings.map { |hearing| hearing.appeal.veteran.participant_id }
            response_participant_ids = response_body["hearings"].map { |hearing| hearing["participant_id"] }
            expect(response_participant_ids).to match_array(expected_participant_ids)
          end

          context "is virtual" do
            include_examples "hearings api route that serializes virtual hearing"
          end
        end

        context "legacy hearings" do
          let!(:hearings) do
            [
              create(:legacy_hearing, regional_office: "RO42", hearing_day: hearing_day)
            ]
          end

          subject do
            get :show, params: { hearing_day: "2019-07-07" }
            response
          end

          it "returns a 200 and response has expected attributes and values", :aggregate_failures do
            expect(subject.status).to eq 200

            response_body = JSON.parse(subject.body)
            expect(response_body).to have_key("hearings")
            expect(response_body["hearings"].size).to eq 1
            expect(response_body["hearings"][0]["is_virtual"]).to eq(false)
          end

          context "is virtual" do
            include_examples "hearings api route that serializes virtual hearing"
          end
        end
      end

      context "response for multiple hearing days matching date" do
        let!(:hearing_days) do
          [
            create(:hearing_day, scheduled_for: Date.new(2019, 8, 8), room: "1"),
            create(:hearing_day, scheduled_for: Date.new(2019, 8, 8), room: "2")
          ]
        end
        let!(:hearings) do
          [
            create(:hearing, regional_office: "RO42", hearing_day: hearing_days[0]),
            create(:hearing, hearing_day: hearing_days[0]),
            create(:legacy_hearing, hearing_day: hearing_days[1]),
            create(:legacy_hearing, regional_office: "RO42", hearing_day: hearing_days[1])
          ]
        end

        subject do
          get :show, params: { hearing_day: "2019-08-08" }
          response
        end

        it "returns a 200 and response has expected attributes and values", :aggregate_failures do
          expect(subject.status).to eq 200
          response_body = JSON.parse(subject.body)
          expect(response_body).to have_key("hearings")

          json_hearings = response_body["hearings"]
          expect(json_hearings.size).to eq 2
          expect(json_hearings.map { |hearing| hearing["scheduled_for"] }).to all(start_with("2019-08-08"))
        end
      end
    end

    context "with API that does not exists" do
      let(:api_key) { "does-not-exist" }

      it "returns a 401 error with invalid date" do
        get :show, params: { hearing_day: "invalid" }
        expect(response.status).to eq 401
      end

      it "returns a 401 error with a valid date" do
        get :show, params: { hearing_day: "2019-07-07" }
        expect(response.status).to eq 401
      end
    end
  end
end
