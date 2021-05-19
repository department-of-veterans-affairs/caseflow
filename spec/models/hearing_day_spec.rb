# frozen_string_literal: true

describe HearingDay, :all_dbs do
  context "#create" do
    let(:test_hearing_date_vacols) do
      current_date = Time.zone.today
      Time.use_zone("Eastern Time (US & Canada)") do
        Time.zone.local(current_date.year, current_date.month, current_date.day, 8, 30, 0).to_datetime
      end
    end

    let(:test_hearing_date_caseflow) do
      Time.zone.local(2019, 5, 15).to_date
    end

    context "add a hearing_day with only required attributes - VACOLS" do
      let(:hearing_day) do
        build(
          :hearing_day,
          request_type: HearingDay::REQUEST_TYPES[:central],
          scheduled_for: test_hearing_date_vacols,
          room: "1"
        )
      end

      it "creates hearing_day with required attributes", :aggregate_failures do
        expect(hearing_day.request_type).to eq "C"
        expect(hearing_day.scheduled_for.strftime("%Y-%m-%d"))
          .to eq test_hearing_date_vacols.strftime("%Y-%m-%d")
        expect(hearing_day.room).to eq "1"
      end
    end

    context "add a hearing_day with only required attributes - Caseflow" do
      let(:hearing_day) do
        build(
          :hearing_day,
          request_type: HearingDay::REQUEST_TYPES[:central],
          scheduled_for: test_hearing_date_caseflow,
          room: "1"
        )
      end

      it "creates hearing_day with required attributes", :aggregate_failures do
        expect(hearing_day.request_type).to eq "C"
        expect(hearing_day.scheduled_for.strftime("%Y-%m-%d"))
          .to eq test_hearing_date_caseflow.strftime("%Y-%m-%d")
        expect(hearing_day.room).to eq "1"
      end
    end

    context "add a video hearing day - Caseflow" do
      let(:hearing_day) do
        build(
          :hearing_day,
          request_type: HearingDay::REQUEST_TYPES[:video],
          scheduled_for: test_hearing_date_caseflow,
          regional_office: "RO89",
          room: "5"
        )
      end

      it "creates a video hearing day", :aggregate_failures do
        expect(hearing_day.request_type).to eq "V"
        expect(hearing_day.scheduled_for.strftime("%Y-%m-%d %H:%M:%S"))
          .to eq test_hearing_date_caseflow.strftime("%Y-%m-%d %H:%M:%S")
        expect(hearing_day.regional_office).to eq "RO89"
        expect(hearing_day.room).to eq "5"
      end
    end

    context "video hearing day with invalid RO key" do
      subject do
        create(
          :hearing_day,
          request_type: HearingDay::REQUEST_TYPES[:video],
          regional_office: "RO1000"
        )
      end

      it "throws a validation error" do
        expect { subject }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Regional office key (RO1000) is invalid"
        )
      end
    end

    context "central hearing day with a non-nil RO key" do
      subject do
        create(
          :hearing_day,
          request_type: HearingDay::REQUEST_TYPES[:central],
          regional_office: "RO10"
        )
      end

      it "throws a validation error" do
        expect { subject }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Regional office must be blank"
        )
      end
    end

    context "hearing day with invalid request type" do
      subject { create(:hearing_day, request_type: "abcdefg", regional_office: "RO10") }

      it "throws a validation error" do
        expect { subject }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Request type is invalid"
        )
      end
    end

    context "hearing day with judge id that does not exist" do
      subject do
        create(
          :hearing_day,
          request_type: HearingDay::REQUEST_TYPES[:video],
          regional_office: "RO10",
          judge_id: 9876
        )
      end

      it "throws a validation error" do
        expect { subject }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Judge can't be blank"
        )
      end
    end
  end

  context "update hearing day" do
    let!(:hearing_day) do
      create(
        :hearing_day,
        request_type: HearingDay::REQUEST_TYPES[:video],
        regional_office: "RO18"
      )
    end
    let(:hearing_day_hash) do
      {
        request_type: HearingDay::REQUEST_TYPES[:video],
        scheduled_for: Date.new(2019, 12, 7),
        regional_office: "RO89",
        room: "5",
        lock: true
      }
    end

    subject { hearing_day.update!(hearing_day_hash) }

    it "updates attributes", :aggregate_failures do
      subject

      updated_hearing_day = HearingDay.find(hearing_day.id).reload
      expect(updated_hearing_day.request_type).to eql(HearingDay::REQUEST_TYPES[:video])
      expect(updated_hearing_day.scheduled_for).to eql(Date.new(2019, 12, 7))
      expect(updated_hearing_day.regional_office).to eql("RO89")
      expect(updated_hearing_day.room).to eql("5")
      expect(updated_hearing_day.lock).to eql(true)
    end

    context "updates attributes in children hearings" do
      let!(:vacols_child_hearing) do
        create(:case_hearing, vdkey: hearing_day.id, folder_nr: create(:case).bfkey)
      end
      let!(:caseflow_child_hearing) { create(:hearing, hearing_day_id: hearing_day.id) }

      before do
        RequestStore.store[:current_user] = create(:user, vacols_uniq_id: create(:staff).slogid)
      end

      it "updates children hearings with a new room", :aggregate_failures do
        subject

        updated_vacols_child_hearing = vacols_child_hearing.reload
        expect(updated_vacols_child_hearing[:room]).to eql "5"
        updated_caseflow_child_hearing = caseflow_child_hearing.reload
        expect(updated_caseflow_child_hearing.room).to eql "5"
      end

      it "only tries to update the room, because that's all that changed in the hearing day" do
        expect_any_instance_of(LegacyHearing).to receive(:update!).with(room: "5")
        expect_any_instance_of(Hearing).to receive(:update!).with(room: "5")

        subject
      end

      context "both room and judge are changed" do
        let!(:judge) { create(:user) }
        let!(:judge_role) { create(:staff, :judge_role, sdomainid: judge.css_id) }
        let!(:hearing_day_hash) do
          {
            judge_id: judge.id,
            request_type: HearingDay::REQUEST_TYPES[:video],
            scheduled_for: Date.new(2019, 12, 7),
            regional_office: "RO89",
            room: "5",
            lock: true
          }
        end

        it "updates children hearings with a new room and judge", :aggregate_failures do
          subject

          updated_vacols_child_hearing = vacols_child_hearing.reload
          expect(updated_vacols_child_hearing[:room]).to eql "5"
          expect(updated_vacols_child_hearing[:board_member]).to eql judge.vacols_attorney_id
          updated_caseflow_child_hearing = caseflow_child_hearing.reload
          expect(updated_caseflow_child_hearing.room).to eql "5"
          expect(updated_caseflow_child_hearing.judge).to eql judge
        end

        it "only tries to update the room and the judge, because that's all that changed in the hearing day" do
          expected_legacy_params = { room: "5", judge_id: judge.id }
          expect_any_instance_of(LegacyHearing).to receive(:update!).with(**expected_legacy_params)
          expected_ama_params = { room: "5", judge_id: judge.id }
          expect_any_instance_of(Hearing).to receive(:update!).with(**expected_ama_params)

          subject
        end
      end
    end
  end

  context "confirm_no_children_records" do
    let!(:hearing_day) { create(:hearing_day) }
    let!(:hearing) { create(:hearing, hearing_day: hearing_day) }

    it "returns an error if there are children records" do
      expect { hearing_day.reload.confirm_no_children_records }.to raise_error(HearingDay::HearingDayHasChildrenRecords)
    end
  end

  # One ro from each timezone in the continental US
  selected_ro_ids = [
    "RO58", # Manila, "Asia/Manila"
    "RO01", # Boston, "America/New_York"
    "RO20", # Nashville, "America/Chicago"
    "RO39", # Denver, "America/Denver"
    "RO45", # Phoenix, "America/Phoenix"
    "RO46"  # Seattle, "America/Los_Angeles"
  ]

  context "total_slots" do
    context "with no db value for number_of_slots" do
      subject { hearing_day.total_slots }
      let(:hearing_day) do
        create(
          :hearing_day,
          request_type: request_type,
          regional_office: regional_office_key
        )
      end

      context "a virtual day" do
        let(:request_type) { HearingDay::REQUEST_TYPES[:virtual] }
        let(:regional_office_key) { nil }
        it "has 8 slots" do
          expect(subject).to be(8)
        end
      end

      context "a central day" do
        let(:regional_office_key) { nil }
        let(:request_type) { HearingDay::REQUEST_TYPES[:central] }
        it "has 10 slots" do
          expect(subject).to be(10)
        end
      end

      selected_ro_ids.each do |ro|
        context "a video day at RO (#{ro})" do
          let(:regional_office_key) { ro }
          let(:request_type) { HearingDay::REQUEST_TYPES[:video] }
          it "has 12 slots" do
            expect(subject).to be(12)
          end
        end
      end
    end

    context "with number_of_slots set to 13" do
      subject { hearing_day.total_slots }
      let(:number_of_slots) { 13 }
      let(:hearing_day) do
        create(
          :hearing_day,
          request_type: request_type,
          regional_office: regional_office_key,
          number_of_slots: number_of_slots
        )
      end

      context "a virtual day" do
        let(:request_type) { HearingDay::REQUEST_TYPES[:virtual] }
        let(:regional_office_key) { nil }
        it "has 13 slots" do
          expect(subject).to be(13)
        end
      end
      context "a central day" do
        let(:regional_office_key) { nil }
        let(:request_type) { HearingDay::REQUEST_TYPES[:central] }
        it "has 13 slots" do
          expect(subject).to be(13)
        end
      end
      context "a video day at RO (RO20)" do
        let(:regional_office_key) { "RO20" }
        let(:request_type) { HearingDay::REQUEST_TYPES[:video] }
        it "has 13 slots" do
          expect(subject).to be(13)
        end
      end
    end
  end

  context "begins_at" do
    context "no db value for begins_at" do
      subject { hearing_day.begins_at }
      let(:first_slot_time) { nil }
      let(:scheduled_for) { Date.tomorrow } # Same as default, but need it for expects
      let(:hearing_day) do
        create(
          :hearing_day,
          request_type: request_type,
          regional_office: regional_office_key,
          first_slot_time: first_slot_time,
          scheduled_for: scheduled_for
        )
      end
      context "a virtual day" do
        let(:request_type) { HearingDay::REQUEST_TYPES[:virtual] }
        let(:regional_office_key) { nil }
        it "begins_at 8:30 eastern" do
          expected_begins_at = scheduled_for.in_time_zone("America/New_York").change(hour: 8, min: 30)
          expect(Time.zone.parse(subject)).to eq(expected_begins_at)
        end
      end
      context "a central day" do
        let(:regional_office_key) { nil }
        let(:request_type) { HearingDay::REQUEST_TYPES[:central] }
        it "begins_at 9:00 eastern" do
          expected_begins_at = scheduled_for.in_time_zone("America/New_York").change(hour: 9, min: 0)
          expect(Time.zone.parse(subject)).to eq(expected_begins_at)
        end
      end
      selected_ro_ids.each do |ro|
        context "a video day at RO (#{ro})" do
          let(:regional_office_key) { ro }
          let(:request_type) { HearingDay::REQUEST_TYPES[:video] }

          regional_office_info = RegionalOffice::CITIES[ro]
          regional_office_timezone = regional_office_info[:timezone]

          it "begins_at 08:30 ro timezone" do
            expected_begins_at = scheduled_for.in_time_zone(regional_office_timezone).change(hour: 8, min: 30)
            expect(Time.zone.parse(subject)).to eq(expected_begins_at)
          end
        end
      end
    end

    context "with a db value for begins_at" do
      subject { hearing_day.begins_at }
      let(:first_slot_time) { "13:38" }
      let(:scheduled_for) { Date.tomorrow } # Same as default, but need it for expects
      let(:hearing_day) do
        create(
          :hearing_day,
          request_type: request_type,
          regional_office: regional_office_key,
          first_slot_time: first_slot_time,
          scheduled_for: scheduled_for
        )
      end

      def format_begins_at_from_db(time_string, scheduled_for)
        db_hour, db_minute = time_string.split(":")

        scheduled_for.in_time_zone("America/New_York").change(hour: db_hour, min: db_minute)
      end

      context "a virtual day" do
        let(:request_type) { HearingDay::REQUEST_TYPES[:virtual] }
        let(:regional_office_key) { nil }
        it "begins_at db value" do
          expect(Time.zone.parse(subject)).to eq(format_begins_at_from_db(first_slot_time, scheduled_for))
        end
      end
      context "a central day" do
        let(:regional_office_key) { nil }
        let(:request_type) { HearingDay::REQUEST_TYPES[:central] }
        it "begins_at db value" do
          expect(Time.zone.parse(subject)).to eq(format_begins_at_from_db(first_slot_time, scheduled_for))
        end
      end
      selected_ro_ids.each do |ro|
        context "a video day at RO (#{ro})" do
          let(:regional_office_key) { ro }
          let(:request_type) { HearingDay::REQUEST_TYPES[:video] }
          it "begins_at db value" do
            expect(Time.zone.parse(subject)).to eq(format_begins_at_from_db(first_slot_time, scheduled_for))
          end
        end
      end
    end
  end

  context "slot_length_minutes" do
    context "no db value for slot_length_minutes" do
      subject { hearing_day.slot_length_minutes }
      let(:hearing_day) { create(:hearing_day) }
      it "uses default value of 60" do
        expect(subject).to eq(60)
      end
    end
    context "with a db value for slot_length_minutes" do
      subject { hearing_day.slot_length_minutes }
      let(:hearing_day) { create(:hearing_day, slot_length_minutes: 45) }
      it "uses db value for slot_length_minutes" do
        expect(subject).to eq(45)
      end
    end
  end

  context "hearing day full" do
    context "the hearing day has 12 scheduled hearings" do
      let!(:hearing_day) { create(:hearing_day) }

      before do
        6.times do
          create(:hearing, hearing_day: hearing_day)
          create(:case_hearing, vdkey: hearing_day.id)
        end
      end

      subject { hearing_day.reload.hearing_day_full? }

      it do
        expect(subject).to eql(true)
      end
    end

    context "the hearing day has 10 closed hearings" do
      let!(:hearing_day) { create(:hearing_day) }

      before do
        5.times do
          create(:hearing, hearing_day: hearing_day, disposition: "postponed")
          create(
            :case_hearing,
            vdkey: hearing_day.id,
            hearing_disp: VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:cancelled]
          )
        end
      end

      subject { hearing_day.reload.hearing_day_full? }

      it do
        expect(subject).to eql(false)
      end
    end

    context "the hearing day is locked" do
      let!(:hearing_day) { create(:hearing_day, lock: true) }

      subject { hearing_day.reload.hearing_day_full? }

      it do
        expect(subject).to eql(true)
      end
    end
  end

  context "bulk persist" do
    let(:schedule_period) do
      RequestStore[:current_user] = User.create(css_id: "BVASCASPER1", station_id: 101)
      Generators::Vacols::Staff.create(stafkey: "SCASPER1", sdomainid: "BVASCASPER1", slogid: "SCASPER1")
      create(:ro_schedule_period)
    end

    context "generate and persist hearing schedule" do
      before do
        HearingDay.create_schedule(schedule_period.algorithm_assignments)
      end

      subject { HearingDayRange.new(schedule_period.start_date, schedule_period.end_date).load_days }

      it do
        expect(subject.size).to eql(970)
      end
    end
  end
end
