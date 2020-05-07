# frozen_string_literal: true

require "models/concerns/has_virtual_hearing_examples"

describe LegacyHearing, :all_dbs do
  it_should_behave_like "a model that can have a virtual hearing" do
    let(:instance_of_class) do
      create(:legacy_hearing, regional_office: "RO42")
    end
  end

  before do
    RequestStore[:current_user] = create(:user, css_id: "Test user", station_id: "101")
  end

  let(:hearing) do
    create(
      :legacy_hearing,
      scheduled_for: scheduled_for,
      disposition: disposition,
      hold_open: hold_open,
      request_type: request_type,
      regional_office: regional_office
    )
  end

  let(:hearing2) do
    create(
      :legacy_hearing,
      scheduled_for: scheduled_for,
      disposition: disposition,
      hold_open: hold_open,
      request_type: request_type,
      regional_office: regional_office
    )
  end

  let(:scheduled_for) { Time.zone.yesterday }
  let(:disposition) { nil }
  let(:hold_open) { nil }
  let(:request_type) { HearingDay::REQUEST_TYPES[:video] }
  let(:regional_office) { "RO13" }

  context "#location" do
    subject { hearing.request_type_location }

    it { is_expected.to eq("Baltimore regional office") }

    context "when it's a central office hearing" do
      let(:request_type) { HearingDay::REQUEST_TYPES[:central] }

      it { is_expected.to eq("Board of Veterans' Appeals in Washington, DC") }
    end
  end

  context "#disposition_editable" do
    subject { hearing.disposition_editable }

    context "when the hearing does not have a hearing_task_association" do
      it { is_expected.to eq(true) }
    end

    context "when the hearing has an open disposition task" do
      let!(:hearing_task_association) { create(:hearing_task_association, hearing: hearing) }
      let!(:disposition_task) do
        create(:assign_hearing_disposition_task, parent: hearing_task_association.hearing_task)
      end

      it { is_expected.to eq(true) }
    end

    context "when the hearing has a cancelled disposition task" do
      let!(:hearing_task_association) { create(:hearing_task_association, hearing: hearing) }
      let!(:disposition_task) do
        create(:assign_hearing_disposition_task,
               :cancelled,
               parent: hearing_task_association.hearing_task)
      end

      before do
        hearing_task_association.hearing_task.update(status: :in_progress)
      end

      it { is_expected.to eq(false) }
    end

    context "when the hearing has a disposition task with children" do
      let!(:hearing_task_association) { create(:hearing_task_association, hearing: hearing) }
      let!(:disposition_task) do
        create(:assign_hearing_disposition_task, parent: hearing_task_association.hearing_task)
      end
      let!(:transcription_task) { create(:transcription_task, parent: disposition_task) }

      it { is_expected.to eq(false) }
    end
  end

  context "#no_show?" do
    subject { hearing.no_show? }
    let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.no_show }

    it { is_expected.to be_truthy }
  end

  context "#held_open?" do
    subject { hearing.held_open? }

    context "hold_open is nil" do
      it { is_expected.to be_falsey }
    end

    context "hold_open is zero" do
      let(:hold_open) { 0 }
      it { is_expected.to be_falsey }
    end

    context "hold_open is positive number" do
      let(:hold_open) { 30 }
      it { is_expected.to be_truthy }
    end
  end

  context "#hold_release_date" do
    subject { hearing.hold_release_date }

    context "when held open" do
      let(:hold_open) { 30 }
      it { is_expected.to eq(29.days.from_now.to_date) }
    end

    context "when not held open" do
      it { is_expected.to eq(nil) }
    end
  end

  context "#no_show_excuse_letter_due_date" do
    subject { hearing.no_show_excuse_letter_due_date }

    it { is_expected.to eq(14.days.from_now.to_date) }
  end

  context "#active_appeal_streams" do
    subject { hearing.active_appeal_streams }

    let!(:appeal1) do
      create(:legacy_appeal, vacols_case: create(:case_with_form_9, bfcorlid: "123C"))
    end
    let!(:appeal2) do
      create(:legacy_appeal, vacols_case:
        create(:case_with_decision, :status_remand, :disposition_remanded, bfcorlid: "123C"))
    end
    let!(:appeal3) do
      create(:legacy_appeal, vacols_case:
        create(
          :case_with_form_9,
          :status_complete,
          :type_post_remand,
          :disposition_allowed,
          folder: build(:folder, tioctime: 1.day.ago),
          bfcorlid: "123C"
        ))
    end
    let!(:appeal4) do
      create(:legacy_appeal, vacols_case: create(:case_with_notification_date, bfcorlid: "123C"))
    end

    let(:hearing) { create(:legacy_hearing, appeal: appeal1) }

    it "returns active appeals with no decision date and with form9 date" do
      expect(subject.size).to eq 3
    end

    it "returns snapshot appeals from postgres database even if changes happened in vacols" do
      expect(subject.size).to eq 3
      VACOLS::Case.find(appeal2.vacols_id).delete
      VACOLS::Case.find(appeal1.vacols_id).delete

      expect(subject.size).to eq 3
    end
  end

  context "#to_hash_for_worksheet" do
    subject { hearing.to_hash_for_worksheet(nil).with_indifferent_access }

    let(:vbms_id) { "12345678" }
    let!(:veteran) { create(:veteran, file_number: vbms_id) }
    let(:appeal) do
      create(:legacy_appeal, vacols_case:
        create(:case_with_form_9, bfcorlid: vbms_id, case_issues: [create(:case_issue)]))
    end
    let!(:additional_appeal) do
      create(:legacy_appeal, vacols_case:
        create(:case_with_form_9, bfkey: "other id", bfcorlid: vbms_id, case_issues: [create(:case_issue)]))
    end
    let!(:hearing) do
      create(:legacy_hearing, appeal: appeal, case_hearing: create(:case_hearing, folder_nr: appeal.vacols_id))
    end

    context "when hearing has appeals ready for hearing" do
      it "should contain appeal streams and associated worksheet issues" do
        expect(subject["appeals_ready_for_hearing"].size).to eq 2
        # pending_hearing generator has 1 issue
        expect(subject["appeals_ready_for_hearing"][0]["worksheet_issues"].size).to eq 1
        expect(subject["appeals_ready_for_hearing"][1]["worksheet_issues"].size).to eq 1
      end
    end

    context "when a hearing & appeal exist" do
      it "returns expected keys" do
        expect(subject["appellant_address_line_1"]).to eq(appeal.appellant_address_line_1)
        expect(subject["appellant_address_line_2"]).to eq(appeal.appellant_address_line_2)
        expect(subject["appellant_city"]).to eq(appeal.appellant_city)
        expect(subject["appellant_country"]).to eq(appeal.appellant_country)
        expect(subject["appellant_state"]).to eq(appeal.appellant_state)
        expect(subject["appellant_zip"]).to eq(appeal.appellant_zip)
        expect(subject["veteran_age"]).to eq(appeal.veteran_age)
        expect(subject["veteran_gender"]).to eq(appeal.veteran_gender)
        expect(subject["veteran_first_name"]).to eq(hearing.veteran_first_name)
        expect(subject["veteran_last_name"]).to eq(hearing.veteran_last_name)
        expect(subject["appellant_last_first_mi"]).to eq(hearing.appellant_last_first_mi)
        expect(subject["cached_number_of_documents"]).to eq 3
      end
    end
  end

  context "#military_service" do
    subject { hearing.military_service }
    let(:case_hearing) { create(:case_hearing) }
    let(:hearing) { LegacyHearing.create(vacols_id: case_hearing.hearing_pkseq, military_service: military_service) }

    context "when military service is not set" do
      let(:military_service) { nil }

      context "when appeal is not set" do
        it { is_expected.to eq nil }
      end

      context "when appeal is set" do
        let(:appeal) { create(:legacy_appeal, :with_veteran, vacols_case: create(:case_with_form_9)) }

        it "should load military service from appeal" do
          hearing.update(appeal: appeal)
          expect(subject).to eq appeal.veteran.periods_of_service.join("\n")
        end
      end
    end

    context "when military service is set" do
      let(:military_service) { "Test" }
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case_with_form_9)) }

      it "should load military service from appeal" do
        hearing.update(appeal: appeal)
        expect(subject).to eq "Test"
      end
    end
  end

  context ".current_issue_count" do
    subject { hearing.current_issue_count }
    let(:appeal1) do
      create(:legacy_appeal, vacols_case:
        create(:case_with_form_9, bfcorlid: "123C", case_issues: create_list(:case_issue, 2)))
    end
    let(:appeal2) { create(:legacy_appeal, vacols_case: create(:case_with_form_9, bfcorlid: "123C")) }
    let(:hearing) { create(:legacy_hearing, appeal: appeal1) }
    it "should return the current hearing count from all active appeals" do
      expect(subject).to eq 2
    end
  end

  context ".assign_or_create_from_vacols_record" do
    let(:case_hearing) do
      create(:case_hearing, folder_nr: "5678")
    end

    let(:vacols_record) do
      OpenStruct.new(hearing_pkseq: case_hearing.hearing_pkseq, folder_nr: case_hearing.folder_nr, css_id: "1111")
    end

    let!(:user) { User.create(css_id: "1111", station_id: "123") }
    let!(:appeal) { build(:legacy_appeal, vacols_case: create(:case, bfkey: "5678")) }

    context "create vacols record" do
      subject { LegacyHearing.assign_or_create_from_vacols_record(vacols_record) }

      it "should create a legacy hearing record" do
        subject
        hearing = LegacyHearing.find_by(vacols_id: case_hearing.hearing_pkseq)
        expect(hearing.present?).to be true
        expect(hearing.appeal.vacols_id).to eq "5678"
        expect(hearing.user).to eq user
        expect(hearing.prepped).to be_falsey
      end
    end

    context "assign vacols record" do
      let(:case_hearing) do
        create(:case_hearing, folder_nr: "5678")
      end

      let(:vacols_record) do
        OpenStruct.new(hearing_pkseq: case_hearing.hearing_pkseq, folder_nr: case_hearing.folder_nr, css_id: "1111")
      end

      let!(:existing_user) { User.create(css_id: vacols_record[:css_id], station_id: "123") }
      let!(:user) { User.create(css_id: "1112", station_id: "123") }
      let!(:hearing) { LegacyHearing.create(vacols_id: case_hearing.hearing_pkseq, user: user) }
      subject { LegacyHearing.assign_or_create_from_vacols_record(vacols_record, legacy_hearing: hearing) }

      it "should create a hearing record and reassign user" do
        expect(subject.present?).to be true
        expect(subject.appeal.vacols_id).to eq "5678"
        expect(subject.user).to eq existing_user
        expect(subject.prepped).to be_falsey
      end
    end
  end

  context "#update" do
    subject { hearing.update(hearing_hash) }
    let(:hearing) { create(:legacy_hearing) }

    context "when Vacols does not need an update" do
      let(:hearing_hash) do
        {
          military_service: "Vietnam 1968 - 1970",
          witness: "Jane Smith attended",
          prepped: true
        }
      end

      it "updates hearing columns" do
        subject
        expect(hearing.military_service).to eq "Vietnam 1968 - 1970"
        expect(hearing.witness).to eq "Jane Smith attended"
        expect(hearing.prepped).to be_truthy
      end
    end

    context "when Vacols needs an update" do
      let(:hearing_hash) do
        { notes: "test notes",
          aod: :granted,
          transcript_requested: false,
          disposition: :postponed,
          add_on: true,
          hold_open: 60,
          representative_name: "DAV - DON REED" }
      end

      it "updates vacols hearing" do
        expect(hearing.notes).to eq nil
        expect(hearing.summary).to eq nil
        expect(hearing.aod).to eq nil
        expect(hearing.transcript_requested).to eq nil
        expect(hearing.disposition).to eq nil
        expect(hearing.hold_open).to eq nil
        subject
        expect(hearing.notes).to eq "test notes"
        expect(hearing.summary).to eq nil
        expect(hearing.aod).to eq :granted
        expect(hearing.transcript_requested).to eq false
        expect(hearing.disposition).to eq :postponed
        expect(hearing.add_on).to eq true
        expect(hearing.hold_open).to eq 60
        expect(hearing.representative_name).to eq "DAV - DON REED"
      end
    end
  end

  context "#hearing_day" do
    context "associated hearing day exists" do
      let(:hearing_day) { create(:hearing_day) }
      let(:legacy_hearing) do
        # hearing_day_id is set to nil because the tests are testing if it
        # gets populated correctly. hearing_day is used by the factory to initialize
        # a case hearing in vacols.
        create(:legacy_hearing, hearing_day: hearing_day, hearing_day_id: nil)
      end

      context "and hearing day id refers to a row in Caseflow" do
        it "get hearing day returns the associated hearing day successfully" do
          expect(legacy_hearing.hearing_day).to eq hearing_day
        end

        it "get hearing day calls update once" do
          expect(legacy_hearing).to receive(:update!).once

          legacy_hearing.hearing_day
        end

        it "get hearing day calls VACOLS only once" do
          expect(HearingRepository).to receive(:load_vacols_data).once

          legacy_hearing.hearing_day
          legacy_hearing.hearing_day
        end
      end

      context "and hearing day id refers to a row in VACOLS" do
        let(:hearing_day) do
          create(
            :hearing_day,
            scheduled_for: Time.zone.local(2018, 1, 1),
            request_type: HearingDay::REQUEST_TYPES[:central]
          )
        end

        it "get hearing day returns nil" do
          expect(legacy_hearing.hearing_day).to eq nil
        end

        it "get hearing day calls hearing_day_id_refers_to_vacols_row" do
          expect(legacy_hearing).to receive(:hearing_day_id_refers_to_vacols_row?).once

          legacy_hearing.hearing_day
        end

        it "get hearing day never calls update!" do
          expect(legacy_hearing).to_not receive(:update!)

          legacy_hearing.hearing_day
        end
      end
    end

    context "associated hearing day does not exist" do
      let(:legacy_hearing) do
        create(
          :legacy_hearing,
          hearing_day_id: nil,
          case_hearing: create(:case_hearing, vdkey: "123456")
        )
      end

      it "get hearing day returns nil" do
        expect(legacy_hearing.hearing_day).to eq nil
      end
    end
  end

  context "#scheduled_for_past?" do
    context "for a video hearing scheduled before 4/1/2019" do
      let(:scheduled_for) do
        Time.use_zone("America/New_York") { Time.zone.local(2018, 1, 1, 0, 0, 0) }
      end

      it "returns true" do
        expect(hearing.scheduled_for_past?).to be(true)
      end
    end

    context "for a video hearing scheduled after 4/1/2019" do
      let(:hearing_day) do
        create(
          :hearing_day,
          scheduled_for: scheduled_for,
          regional_office: regional_office,
          request_type: HearingDay::REQUEST_TYPES[:video]
        )
      end
      let!(:hearing) { create(:legacy_hearing, hearing_day: hearing_day) }

      context "before today" do
        let(:scheduled_for) do
          Time.use_zone("America/New_York") { Time.zone.local(2019, 8, 8, 0, 0, 0) }
        end

        it "returns true" do
          expect(hearing.scheduled_for_past?).to be(true)
        end
      end

      context "for tomorrow" do
        let(:scheduled_for) do
          Time.use_zone("America/New_York") { Time.zone.tomorrow }
        end

        it "returns false" do
          expect(hearing.scheduled_for_past?).to be(false)
        end
      end
    end
  end
end
