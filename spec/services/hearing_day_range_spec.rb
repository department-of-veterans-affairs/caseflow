# frozen_string_literal: true

describe HearingDayRange, :all_dbs do
  describe ".load_days" do
    context "load Video days for a range date" do
      let!(:hearings) do
        [create(:hearing_day, request_type: "V", regional_office: "RO13", scheduled_for: Time.zone.today),
         create(:hearing_day, request_type: "V", regional_office: "RO13", scheduled_for: Time.zone.today + 1.day)]
      end

      subject { HearingDayRange.new(Time.zone.today, Time.zone.today + 1.day, "RO13").load_days }

      it "gets hearings for a date range" do
        expect(subject.size).to eq 2
      end
    end

    context "load Central Office days for a range date" do
      let!(:hearings) do
        [create(:hearing_day, scheduled_for: Time.zone.today),
         create(:hearing_day, scheduled_for: Time.zone.today + 1.day),
         create(:hearing_day, scheduled_for: Time.zone.today + 2.days)]
      end

      subject do
        HearingDayRange.new(Time.zone.today, Time.zone.today + 2.days, HearingDay::REQUEST_TYPES[:central]).load_days
      end

      it "should load all three hearing days" do
        expect(subject.size).to eq 3
      end
    end

    context "Video Hearing parent and child rows for a date range" do
      let(:vacols_case) do
        create(
          :case,
          folder: create(:folder, tinum: "docket-number"),
          bfregoff: "RO13",
          bfcurloc: "57"
        )
      end
      let(:appeal) do
        create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
      end
      let!(:hearing_day) do
        create(:hearing_day, request_type: "V", regional_office: "RO13", scheduled_for: Time.zone.today)
      end
      let!(:hearing) do
        create(:case_hearing, folder_nr: appeal.vacols_id, vdkey: hearing_day.id)
      end

      context "get parent and children structure" do
        subject do
          HearingDayRange.new(
            (hearing.hearing_date - 1).beginning_of_day,
            hearing.hearing_date.beginning_of_day + 10
          ).open_hearing_days_with_hearings_hash
        end

        it "returns nested hash structure" do
          expect(subject.size).to eq 1
          expect(subject[0][:hearings].size).to eq 1
          expect(subject[0][:readable_request_type]).to eq Hearing::HEARING_TYPES[:V]
          expect(subject[0][:hearings][0][:appeal_id]).to eq appeal.id
        end
      end
    end

    context "Video Hearings returns video hearings that are not postponed or cancelled" do
      let(:vacols_case) do
        create(
          :case,
          folder: create(:folder, tinum: "docket-number"),
          bfregoff: "RO13",
          bfcurloc: "57",
          bfdocind: HearingDay::REQUEST_TYPES[:video]
        )
      end
      let(:appeal) do
        create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
      end
      let!(:hearing) do
        create(:case_hearing, folder_nr: appeal.vacols_id)
      end
      let(:vacols_case2) do
        create(
          :case,
          bfregoff: "RO13",
          bfcurloc: "57",
          bfdocind: HearingDay::REQUEST_TYPES[:video]
        )
      end
      let(:appeal2) do
        create(:legacy_appeal, :with_veteran, vacols_case: vacols_case2)
      end
      let!(:hearing2) do
        create(
          :case_hearing, :disposition_postponed, folder_nr: appeal2.vacols_id, vdkey: hearing.vdkey
        )
      end

      subject do
        HearingDayRange.new(
          (hearing.hearing_date - 1).beginning_of_day,
          hearing.hearing_date.beginning_of_day + 1.day
        ).open_hearing_days_with_hearings_hash
      end

      context "get video hearings neither postponed or cancelled" do
        it "returns nested hash structure" do
          expect(subject.size).to eq 1
          expect(subject[0][:hearings].size).to eq 1
          expect(subject[0][:readable_request_type]).to eq Hearing::HEARING_TYPES[:V]
          expect(subject[0][:hearings][0][:appeal_id]).to eq appeal.id
        end
      end

      context "When there are multiple hearings and multiple days" do
        let(:appeal_today) do
          create(
            :legacy_appeal, :with_veteran, vacols_case: create(:case)
          )
        end
        let!(:second_hearing_today) do
          create(:case_hearing, vdkey: hearing.vdkey, folder_nr: appeal_today.vacols_id)
        end
        let(:appeal_tomorrow) do
          create(
            :legacy_appeal, :with_veteran, vacols_case: create(:case)
          )
        end
        let!(:hearing_tomorrow) do
          create(
            :case_hearing, hearing_date: Time.zone.tomorrow, folder_nr: appeal_tomorrow.vacols_id
          )
        end
        let!(:ama_hearing_day) do
          create(:hearing_day,
                 request_type: HearingDay::REQUEST_TYPES[:video],
                 scheduled_for: Time.zone.yesterday,
                 regional_office: "RO13")
        end
        let!(:ama_appeal) { create(:appeal) }
        let!(:ama_hearing) do
          create(:hearing, :with_tasks, hearing_day: ama_hearing_day, appeal: ama_appeal)
        end

        it "returns hearings are mapped to days" do
          subject.sort_by! { |hearing_day| hearing_day[:scheduled_for] }
          expect(subject.size).to eq 3
          expect(subject[0][:hearings][0][:appeal_id]).to eq ama_appeal.id
          expect(subject[1][:hearings].size).to eq 2
          expect(subject[1][:readable_request_type]).to eq Hearing::HEARING_TYPES[:V]
          expect(
            subject[1][:hearings].map { |hearing| hearing[:appeal_id] }
          ).to include(appeal.id, appeal_today.id)
          expect(subject[2][:hearings][0][:appeal_id]).to eq appeal_tomorrow.id
        end
      end

      context "When there are hearing days that are locked" do
        let!(:locked_hearing_day) { create(:hearing_day, lock: true) }

        it "only returns hearing days that are not full" do
          expect(subject.size).to eq 1
        end
      end
    end

    context "Central Office parent and child rows for a date range" do
      let(:vacols_case) do
        create(
          :case,
          folder: create(:folder, tinum: "docket-number"),
          bfregoff: "RO04",
          bfcurloc: "57"
        )
      end
      let(:appeal) do
        create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
      end
      let!(:staff) { create(:staff, stafkey: "RO04", stc2: 2, stc3: 3, stc4: 4) }
      let(:hearing) do
        create(:case_hearing, hearing_type: HearingDay::REQUEST_TYPES[:central], folder_nr: appeal.vacols_id)
      end

      context "get parent and children structure" do
        subject do
          HearingDayRange.new(
            (hearing.hearing_date - 1).beginning_of_day,
            hearing.hearing_date.beginning_of_day + 10,
            HearingDay::REQUEST_TYPES[:central]
          ).open_hearing_days_with_hearings_hash
        end

        it "returns nested hash structure" do
          expect(subject.size).to eq 1
          expect(subject[0][:hearings].size).to eq 1
          expect(subject[0][:readable_request_type]).to eq Hearing::HEARING_TYPES[:C]
          expect(subject[0][:hearings][0][:appeal_id]).to eq appeal.id
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
    let!(:vso_participant_id) { "789" }
    let!(:vso) { create(:vso, participant_id: vso_participant_id) }
    let!(:current_user) { User.authenticate!(css_id: "VSO_USER", roles: ["VSO"]) }
    let!(:track_veteran_task_one) { create(:track_veteran_task, appeal: hearing_one.appeal, assigned_to: vso) }
    let!(:track_veteran_task_two) { create(:track_veteran_task, appeal: hearing_two.appeal, assigned_to: vso) }
    let!(:track_veteran_task_four) { create(:track_veteran_task, appeal: hearing_four.appeal, assigned_to: vso) }
    let(:start_date) { Time.zone.now + 1.day - 1.month }
    let(:end_date) { Time.zone.now - 1.day + 1.year }
    let!(:vso_participant_ids) do
      [
        {
          legacy_poa_cd: "070",
          nm: "VIETNAM VETERANS OF AMERICA",
          org_type_nm: "POA National Organization",
          ptcpnt_id: vso_participant_id
        }
      ]
    end

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
