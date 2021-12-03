# frozen_string_literal: true

describe HearingDayRange, :all_dbs do
  describe ".load_days" do
    let(:start_date) { Time.zone.today }
    let(:end_date) { Time.zone.today + 2.days }

    subject { HearingDayRange.new(start_date, end_date, regional_office_key).load_days }

    context "load Video and Travel days for a range date" do
      let(:regional_office_key) { "RO13" }
      let!(:hearing_days) do
        [
          create(
            :hearing_day,
            :video,
            regional_office: regional_office_key,
            scheduled_for: Time.zone.today
          ),
          create(
            :hearing_day,
            :video,
            regional_office: regional_office_key,
            scheduled_for: Time.zone.today + 1.day
          ),
          create(
            :hearing_day,
            :travel,
            regional_office: regional_office_key,
            scheduled_for: Time.zone.today + 1.day
          )
        ]
      end

      it "gets hearings for a date range" do
        expect(subject.size).to eq 3
      end
    end

    context "load Central Office days for a range date" do
      let(:regional_office_key) { HearingDay::REQUEST_TYPES[:central] }
      let!(:hearing_days) do
        [
          create(:hearing_day, scheduled_for: Time.zone.today),
          create(:hearing_day, scheduled_for: Time.zone.today + 1.day),
          create(:hearing_day, scheduled_for: Time.zone.today + 2.days)
        ]
      end

      it "should load all three hearing days" do
        expect(subject.size).to eq 3
      end
    end

    context "load Virtual days for a range date" do
      let(:regional_office_key) { HearingDay::REQUEST_TYPES[:virtual] }

      context "only virtual hearing days" do
        let!(:hearing_days) do
          [
            create(:hearing_day, :virtual, scheduled_for: Time.zone.today),
            create(:hearing_day, :virtual, scheduled_for: Time.zone.today + 1.day),
            create(:hearing_day, :virtual, scheduled_for: Time.zone.today + 2.days)
          ]
        end

        it "should load all three hearing days" do
          expect(subject.size).to eq 3
        end
      end

      context "mix of virtual, video, and travel hearing days" do
        let!(:hearing_days) do
          [
            create(:hearing_day, :virtual, scheduled_for: Time.zone.today),
            create(:hearing_day, :virtual, scheduled_for: Time.zone.today + 1.day),
            create(:hearing_day, :travel, scheduled_for: Time.zone.today + 1.day),
            create(:hearing_day, :video, scheduled_for: Time.zone.today + 2.days)
          ]
        end

        it "should only load 2 hearing days" do
          expect(subject.size).to eq 2
        end
      end
    end
  end

  describe ".upcoming_days_for_vso_user" do
    let!(:hearing_day_one) { create(:hearing_day, judge: create(:user, full_name: "Leocadia Jarecki")) }
    let!(:hearing_day_two) { create(:hearing_day, judge: create(:user, full_name: "Ayame Jouda")) }
    let!(:hearing_day_three) { create(:hearing_day, judge: create(:user, full_name: "Clovis Jolla")) }
    let!(:hearing_day_four) { create(:hearing_day, judge: create(:user, full_name: "Geraldine Juniel")) }
    let!(:hearing_one) { create(:hearing, :with_tasks, hearing_day: hearing_day_one) }
    let!(:case_hearing_two) { create(:case_hearing, vdkey: hearing_day_two.id) }
    let!(:hearing_two) { create(:legacy_hearing, hearing_day: hearing_day_two, case_hearing: case_hearing_two) }
    let!(:case_hearing_four) { create(:case_hearing, vdkey: hearing_day_four.id) }
    let!(:hearing_three) { create(:hearing, :with_tasks, hearing_day: hearing_day_three) }
    let!(:hearing_four) { create(:legacy_hearing, hearing_day: hearing_day_four, case_hearing: case_hearing_four) }
    let!(:vso_participant_id) { Fakes::BGSServicePOA::VIETNAM_VETERANS_VSO_PARTICIPANT_ID }
    let!(:vso) { create(:vso, participant_id: vso_participant_id) }
    let!(:current_user) { User.authenticate!(css_id: "VSO_USER", roles: ["VSO"]) }
    let!(:track_veteran_task_one) { create(:track_veteran_task, appeal: hearing_one.appeal, assigned_to: vso) }
    let!(:track_veteran_task_two) { create(:track_veteran_task, appeal: hearing_two.appeal, assigned_to: vso) }
    let!(:track_veteran_task_four) { create(:track_veteran_task, appeal: hearing_four.appeal, assigned_to: vso) }
    let(:start_date) { Time.zone.now + 1.day - 1.month }
    let(:end_date) { Time.zone.now - 1.day + 1.year }
    let!(:vso_participant_ids) { Fakes::BGSServicePOA.default_vsos_poas }

    subject { HearingDayRange.new(start_date, end_date).upcoming_days_for_vso_user(current_user) }

    before do
      stub_const("BGSService", ExternalApi::BGSService)
      RequestStore[:current_user] = current_user

      allow_any_instance_of(BGS::SecurityWebService).to receive(:find_participant_id)
        .with(css_id: current_user.css_id, station_id: current_user.station_id).and_return(vso_participant_id)
      allow_any_instance_of(BGS::OrgWebService).to receive(:find_poas_by_ptcpnt_id)
        .with(vso_participant_id).and_return(vso_participant_ids)
    end

    it "only returns hearing days with VSO assigned hearings" do
      expect(subject.count).to eq 3
      expect(HearingDay.count).to eq 4
      expect(subject.pluck(:id)).to match_array [hearing_day_one.id, hearing_day_two.id, hearing_day_four.id]
    end
  end
end
