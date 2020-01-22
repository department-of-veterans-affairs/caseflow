# frozen_string_literal: true

describe Hearings::HearingDayController, :all_dbs do
  let(:user) { create(:user, roles: ["Build HearSched"]) }

  before do
    User.authenticate!(user: user)
  end

  context "GET index" do
    let(:params) { {} }

    subject { get :index, params: params, as: :json }

    context "with invalid date range" do
      let(:params) { { start_date: "START_DATE", end_date: "END_DATE" } }

      it "returns 400" do
        expect(subject.status).to eq 400
      end
    end

    context "with invalid RO" do
      let(:params) { { regional_office: "BLAH" } }

      it "returns 400" do
        expect(subject.status).to eq 400
      end
    end

    context "with one hearing day within date range" do
      let!(:hearing_day) do
        create(:hearing_day, scheduled_for: Time.zone.now.to_date)
      end
      let(:params) { { start_date: Time.zone.now.to_date - 2.days } }

      it "returns 200 and the hearing day", :aggregate_failures do
        expect(subject.status).to eq 200
        hearing_days = JSON.parse(subject.body)
        expect(hearing_days["hearings"].size).to eq 1
        expect(hearing_days["hearings"][0]["id"]).to eq hearing_day.id
      end
    end

    context "with one hearing day outside of date range" do
      let!(:hearing_day) do
        create(:hearing_day, scheduled_for: Time.zone.now.to_date)
      end
      let(:params) { { start_date: Time.zone.now.to_date + 2.days } }

      it "returns 200 and no hearing days", :aggregate_failures do
        expect(subject.status).to eq 200
        hearing_days = JSON.parse(subject.body)
        expect(hearing_days["hearings"].size).to eq 0
      end
    end

    context "with a virtual hearing returns the right request type" do
      let!(:hearing_day) do
        create(
          :hearing_day,
          scheduled_for: Time.zone.now.to_date,
          regional_office: "RO42",
          request_type: HearingDay::REQUEST_TYPES[:video]
        )
      end
      let(:params) { { start_time: Time.zone.now.to_date - 2.days } }

      shared_examples "route has expected request type" do |request_type|
        it "returns 200 and the has expected type '#{request_type}'", :aggregate_failures do
          expect(subject.status).to eq 200
          hearing_days = JSON.parse(subject.body)
          expect(hearing_days["hearings"].size).to eq 1
          expect(hearing_days["hearings"][0]["id"]).to eq hearing_day.id
          expect(hearing_days["hearings"][0]["readable_request_type"]).to eq request_type
        end
      end

      context "associated with an AMA hearing" do
        let(:hearing) { create(:hearing, hearing_day: hearing_day) }
        let!(:virtual_hearing) { create(:virtual_hearing, :initialized, hearing: hearing) }

        include_examples "route has expected request type", "Virtual"
      end

      context "associated with a Legacy hearing" do
        let(:legacy_hearing) { create(:legacy_hearing, hearing_day: hearing_day) }
        let!(:virtual_hearing) { create(:virtual_hearing, :initialized, hearing: legacy_hearing) }

        include_examples "route has expected request type", "Virtual"
      end

      context "associated with one video and one virtual hearing" do
        let(:hearings) do
          [
            create(:hearing, hearing_day: hearing_day),
            create(:legacy_hearing, hearing_day: hearing_day)
          ]
        end
        let!(:virtual_hearing) do
          create(:virtual_hearing, :initialized, hearing: hearings[0])
        end

        include_examples "route has expected request type", "Video, Virtual"
      end
    end
  end
end
