# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::HearingsController, type: :controller do
  let(:api_key) { ApiKey.create!(consumer_name: "Jobs Tester").key_string }

  before(:each) do
    request.headers["Authorization"] = "Token token=#{api_key}"
  end

  describe "GET hearings by hearing day" do
    context "with valid API key" do
      it "returns 422 with invalid date" do
        get :show, params: { hearing_day: "invalid" }
        expect(response.status).to eq 422
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

        it { expect(subject.status).to eq 200 }
        it { expect(JSON.parse(subject.body)).to have_key("hearings") }
        it { expect(JSON.parse(subject.body)["hearings"]).to eq [] }
      end

      context "response for hearing day with hearings" do
        let(:hearing_day) do
          create(:hearing_day, scheduled_for: Date.new(2019, 7, 7))
        end

        context "ama hearings" do
          let!(:hearings) do
            [
              create(:hearing, hearing_day: hearing_day, scheduled_time: "9:30AM"),
              create(:hearing, hearing_day: hearing_day, scheduled_time: "10:30AM")
            ]
          end

          subject do
            get :show, params: { hearing_day: "2019-07-07" }
            response
          end

          it { expect(subject.status).to eq 200 }
          it { expect(JSON.parse(subject.body)).to have_key("hearings") }
          it { expect(JSON.parse(subject.body)["hearings"].size).to eq 2 }
          it do
            response_body = JSON.parse(subject.body)
            expected_times = hearings.map { |hearing| hearing.scheduled_for }
            scheduled_times = response_body["hearings"].map { |hearing| hearing["scheduled_for"] }

            expect(scheduled_times).to match_array(expected_times)
          end
        end

        context "legacy hearings" do
          let!(:hearings) do
            [
              create(:legacy_hearing, hearing_day: hearing_day)
            ]
          end

          subject do
            get :show, params: { hearing_day: "2019-07-07" }
            response
          end

          it { expect(subject.status).to eq 200 }
          it { expect(JSON.parse(subject.body)).to have_key("hearings") }
          it { expect(JSON.parse(subject.body)["hearings"].size).to eq 1 }
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
