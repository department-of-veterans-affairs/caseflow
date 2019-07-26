# frozen_string_literal: true

require "rails_helper"

describe HearingDay do
  context "#create" do
    let(:hearing) do
      RequestStore[:current_user] = User.create(css_id: "BVASCASPER1", station_id: 101)
      Generators::Vacols::Staff.create(stafkey: "SCASPER1", sdomainid: "BVASCASPER1", slogid: "SCASPER1")
      HearingDay.create_hearing_day(hearing_hash)
    end

    let(:test_hearing_date_vacols) do
      current_date = Time.zone.today
      Time.use_zone("Eastern Time (US & Canada)") do
        Time.zone.local(current_date.year, current_date.month, current_date.day, 8, 30, 0).to_datetime
      end
    end

    let(:test_hearing_date_caseflow) do
      Time.zone.local(2019, 5, 15).to_date
    end

    context "add a hearing with only required attributes - VACOLS" do
      let(:hearing_hash) do
        {
          request_type: HearingDay::REQUEST_TYPES[:central],
          scheduled_for: test_hearing_date_vacols,
          room: "1"
        }
      end

      it "creates hearing with required attributes" do
        expect(hearing["readable_request_type"]).to eq Hearing::HEARING_TYPES[:C]
        expect(hearing["scheduled_for"].strftime("%Y-%m-%d"))
          .to eq test_hearing_date_vacols.strftime("%Y-%m-%d")
        expect(hearing["room"]).to eq "1"
      end
    end

    context "add a hearing with only required attributes - Caseflow" do
      let(:hearing_hash) do
        {
          request_type: HearingDay::REQUEST_TYPES[:central],
          scheduled_for: test_hearing_date_caseflow,
          room: "1"
        }
      end

      it "creates hearing with required attributes" do
        expect(hearing["readable_request_type"]).to eq Hearing::HEARING_TYPES[:C]
        expect(hearing["scheduled_for"].strftime("%Y-%m-%d"))
          .to eq test_hearing_date_caseflow.strftime("%Y-%m-%d")
        expect(hearing["room"]).to eq "1"
      end
    end

    context "add a video hearing - Caseflow" do
      let(:hearing_hash) do
        {
          request_type: HearingDay::REQUEST_TYPES[:central],
          scheduled_for: test_hearing_date_caseflow,
          regional_office: "RO89",
          room: "5"
        }
      end

      it "creates a video hearing" do
        expect(hearing["readable_request_type"]).to eq Hearing::HEARING_TYPES[:C]
        expect(hearing["scheduled_for"].strftime("%Y-%m-%d %H:%M:%S"))
          .to eq test_hearing_date_caseflow.strftime("%Y-%m-%d %H:%M:%S")
        expect(hearing["regional_office"]).to eq "RO89"
        expect(hearing["room"]).to eq "5"
      end
    end
  end

  context "update hearing" do
    let!(:hearing_day) do
      FactoryBot.create(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:video], regional_office: "RO18")
    end
    let(:hearing_hash) do
      {
        request_type: HearingDay::REQUEST_TYPES[:video],
        scheduled_for: Date.new(2019, 12, 7),
        regional_office: "RO89",
        room: "5",
        lock: true
      }
    end

    subject { hearing_day.update!(hearing_hash) }

    it "updates attributes" do
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
        FactoryBot.create(:case_hearing, vdkey: hearing_day.id, folder_nr: FactoryBot.create(:case).bfkey)
      end
      let!(:caseflow_child_hearing) { FactoryBot.create(:hearing, hearing_day_id: hearing_day.id) }

      before do
        RequestStore.store[:current_user] = create(:user, vacols_uniq_id: create(:staff).slogid)
      end

      it "updates children hearings with a new room" do
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
        let!(:judge) { FactoryBot.create(:user) }
        let!(:judge_role) { FactoryBot.create(:staff, :judge_role, sdomainid: judge.css_id) }
        let!(:hearing_hash) do
          {
            judge_id: judge.id,
            request_type: HearingDay::REQUEST_TYPES[:video],
            scheduled_for: Date.new(2019, 12, 7),
            regional_office: "RO89",
            room: "5",
            lock: true
          }
        end

        it "updates children hearings with a new room and judge" do
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
    let!(:hearing_day) { FactoryBot.create(:hearing_day) }
    let!(:hearing) { FactoryBot.create(:hearing, hearing_day: hearing_day) }

    it "returns an error if there are children records" do
      expect { hearing_day.reload.confirm_no_children_records }.to raise_error(HearingDay::HearingDayHasChildrenRecords)
    end
  end

  context "hearing day full" do
    context "the hearing day has 12 scheduled hearings" do
      let!(:hearing_day) { FactoryBot.create(:hearing_day) }

      before do
        6.times do
          FactoryBot.create(:hearing, hearing_day: hearing_day)
          FactoryBot.create(:case_hearing, vdkey: hearing_day.id)
        end
      end

      subject { hearing_day.reload.hearing_day_full? }

      it do
        expect(subject).to eql(true)
      end
    end

    context "the hearing day has 12 closed hearings" do
      let!(:hearing_day) { FactoryBot.create(:hearing_day) }

      before do
        6.times do
          FactoryBot.create(:hearing, hearing_day: hearing_day, disposition: "postponed")
          FactoryBot.create(:case_hearing, vdkey: hearing_day.id, hearing_disp: "C")
        end
      end

      subject { hearing_day.reload.hearing_day_full? }

      it do
        expect(subject).to eql(false)
      end
    end

    context "the hearing day is locked" do
      let!(:hearing_day) { FactoryBot.create(:hearing_day, lock: true) }

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
      FactoryBot.create(:ro_schedule_period)
    end

    context "generate and persist hearing schedule" do
      before do
        HearingDay.create_schedule(schedule_period.algorithm_assignments)
      end

      subject { HearingDayRange.new(schedule_period.start_date, schedule_period.end_date).load_days }

      it do
        expect(subject.size).to eql(434)
      end
    end
  end
end
