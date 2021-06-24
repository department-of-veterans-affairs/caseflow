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

    context "vso user" do
      let(:station_id) { "301" }
      let(:user) { create(:user, roles: ["VSO"], station_id: station_id, regional_office: "RO02") }
      let(:hearing_day_in_range1) do
        create(:hearing_day, scheduled_for: Time.zone.now.to_date + 1.day)
      end
      let(:hearing_day_in_range2) do
        create(
          :hearing_day,
          regional_office: "RO19",
          request_type: HearingDay::REQUEST_TYPES[:video],
          scheduled_for: Time.zone.now.to_date + 2.days
        )
      end
      let(:hearing_day_out_of_range) do
        create(:hearing_day, scheduled_for: Time.zone.now.to_date + 100.days)
      end
      let(:legacy_hearing_in_range1) do
        create(:legacy_hearing, case_hearing: create(:case_hearing, vdkey: hearing_day_in_range1.id))
      end
      let(:legacy_hearing_in_range2) do
        create(:legacy_hearing, case_hearing: create(:case_hearing, vdkey: hearing_day_in_range2.id))
      end
      let(:hearing_out_of_range) { create(:hearing, hearing_day: hearing_day_out_of_range) }

      let(:vso_participant_id) { Fakes::BGSServicePOA::VIETNAM_VETERANS_VSO_PARTICIPANT_ID }
      let(:vso_participant_ids) { Fakes::BGSServicePOA.default_vsos_poas }
      let(:vso) { create(:vso, participant_id: vso_participant_id) }
      let!(:track_veteran_task1) do
        create(:track_veteran_task, appeal: legacy_hearing_in_range1.appeal, assigned_to: vso)
      end
      let!(:track_veteran_task2) do
        create(:track_veteran_task, appeal: legacy_hearing_in_range2.appeal, assigned_to: vso)
      end
      let!(:track_veteran_task3) do
        create(:track_veteran_task, appeal: hearing_out_of_range.appeal, assigned_to: vso)
      end

      before do
        stub_const("BGSService", ExternalApi::BGSService)
        RequestStore[:current_user] = user

        allow_any_instance_of(BGS::SecurityWebService).to receive(:find_participant_id)
          .with(css_id: user.css_id, station_id: user.station_id).and_return(vso_participant_id)
        allow_any_instance_of(BGS::OrgWebService).to receive(:find_poas_by_ptcpnt_id)
          .with(vso_participant_id).and_return(vso_participant_ids)
      end

      shared_context "correct result" do
        it "returns hearing days in correct order", :aggregate_failures do
          expect(subject.status).to eq 200
          hearing_days = JSON.parse(subject.body)
          expect(hearing_days["hearings"].size).to eq 2
          expect(hearing_days["hearings"].pluck("id")).to eq(result)
        end
      end

      context "within default range" do
        let(:result) { [hearing_day_in_range1.id, hearing_day_in_range2.id] }

        include_context "correct result"
      end

      context "hearing days priortized based on user regional office" do
        context "Regional office is 'RO19'" do
          let(:station_id) { "319" }
          let(:result) { [hearing_day_in_range2.id, hearing_day_in_range1.id] }

          include_context "correct result"
        end

        context "Regional office is 'NA'" do
          let(:station_id) { "103" }
          let(:result) { [hearing_day_in_range1.id, hearing_day_in_range2.id] }

          include_context "correct result"
        end

        context "Regional office is 'VACO'" do
          let(:station_id) { "101" }
          let(:result) { [hearing_day_in_range1.id, hearing_day_in_range2.id] }

          include_context "correct result"
        end

        context "Regional office is ambiguous" do
          let(:station_id) { "310" }
          let(:result) { [hearing_day_in_range1.id, hearing_day_in_range2.id] }

          include_context "correct result"
        end
      end
    end
  end
end
