# frozen_string_literal: true

describe AppealRepository, :all_dbs do
  let(:correspondent_record) do
    OpenStruct.new(
      snamef: "Phil",
      snamemi: "J",
      snamel: "Johnston",
      sspare1: "Johnston",
      sspare2: "Chris",
      sspare3: "M",
      susrtyp: "Brother",
      sfnod: 100.days.ago
    )
  end

  let(:folder_record) do
    OpenStruct.new(
      tivbms: "Y",
      tinum: "13 11-265",
      tiread2: "2012091234"
    )
  end

  let(:case_record) do
    OpenStruct.new(
      bfkey: "123C",
      bfcorlid: "VBMS-ID",
      bfac: "4",
      bfso: "Q",
      bfpdnum: "INSURANCE-LOAN-NUMBER",
      bfdrodec: 11.days.ago,
      bfdnod: 10.days.ago,
      bfdsoc: 9.days.ago,
      bfd19: 8.days.ago,
      bfssoc1: 7.days.ago,
      bfssoc2: 6.days.ago,
      bfha: "6",
      bfhr: "1",
      bfregoff: "DSUSER",
      bfdc: "9",
      bfddec: 1.day.ago,
      correspondent: correspondent_record,
      folder: folder_record,
      case_issues: [{
        issdesc: "Issue Description",
        issdc: "1",
        issprog: "Issue Program"
      }]
    )
  end

  context ".build_appeal" do
    before do
      allow_any_instance_of(LegacyAppeal).to receive(:check_and_load_vacols_data!).and_return(nil)
    end

    subject { AppealRepository.build_appeal(case_record) }

    it "returns a new appeal" do
      is_expected.to be_an_instance_of(LegacyAppeal)
    end
  end

  context ".load_vacols_data" do
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
    subject { AppealRepository.load_vacols_data(appeal) }
    it do
      expect(AppealRepository).to receive(:set_vacols_values).exactly(1).times
      is_expected.to eq(true)
    end
  end

  context ".normalize_vacols_date" do
    subject { AppealRepository.normalize_vacols_date(datetime) }

    context "when datetime is nil" do
      let(:datetime) { nil }
      it { is_expected.to be_nil }
    end

    context "when datetime is in a non-UTC timezone" do
      before { Time.zone = "America/Chicago" }
      let(:datetime) { Time.new(2013, 9, 5, 16, 0, 0, "-08:00") }
      it { is_expected.to eq(Time.zone.local(2013, 9, 6)) }
    end
  end

  context ".set_vacols_values" do
    before do
      Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
      allow_any_instance_of(LegacyAppeal).to receive(:check_and_load_vacols_data!).and_return(nil)
    end

    subject do
      appeal = LegacyAppeal.new
      AppealRepository.set_vacols_values(
        appeal: appeal,
        case_record: case_record
      )
    end

    it do
      is_expected.to have_attributes(
        vbms_id: "VBMS-ID",
        type: "Reconsideration",
        file_type: "VBMS",
        veteran_first_name: "Phil",
        veteran_middle_initial: "J",
        veteran_last_name: "Johnston",
        appellant_first_name: "Chris",
        appellant_middle_initial: "M",
        appellant_last_name: "Johnston",
        appellant_relationship: "Brother",
        insurance_loan_number: "INSURANCE-LOAN-NUMBER",
        notification_date: AppealRepository.normalize_vacols_date(11.days.ago),
        nod_date: AppealRepository.normalize_vacols_date(10.days.ago),
        soc_date: AppealRepository.normalize_vacols_date(9.days.ago),
        form9_date: AppealRepository.normalize_vacols_date(8.days.ago),
        ssoc_dates: [
          AppealRepository.normalize_vacols_date(7.days.ago),
          AppealRepository.normalize_vacols_date(6.days.ago)
        ],
        notice_of_death_date: AppealRepository.normalize_vacols_date(100.days.ago),
        hearing_request_type: :central_office,
        hearing_requested: true,
        hearing_held: true,
        regional_office_key: "DSUSER",
        disposition: "Withdrawn",
        decision_date: AppealRepository.normalize_vacols_date(1.day.ago),
        docket_number: "13 11-265",
        citation_number: "2012091234"
      )
    end

    context "bfha set to value not represent a held hearing" do
      let(:case_record) do
        OpenStruct.new(
          correspondent: correspondent_record,
          folder: folder_record,
          bfha: "3",
          case_issues: []
        )
      end

      it { is_expected.to have_attributes(hearing_held: false) }
    end

    context "bfha set to nil" do
      let(:case_record) do
        OpenStruct.new(
          correspondent: correspondent_record,
          folder: folder_record,
          bfha: nil,
          case_issues: []
        )
      end

      it { is_expected.to have_attributes(hearing_held: false) }
    end

    context "No appellant listed" do
      let(:correspondent_record) do
        OpenStruct.new(
          snamef: "Phil",
          snamemi: "J",
          snamel: "Johnston",
          susrtyp: "Brother"
        )
      end

      it { is_expected.to have_attributes(appellant_relationship: "") }
    end

    context "shows cavc as true" do
      let(:case_record) do
        OpenStruct.new(
          correspondent: correspondent_record,
          folder: folder_record,
          bfac: "7",
          case_issues: []
        )
      end

      it { is_expected.to have_attributes(cavc: true) }
    end
  end

  context ".ssoc_dates_from" do
    subject { AppealRepository.ssoc_dates_from(case_record) }
    it do
      is_expected.to be_an_instance_of(Array)
      expect(subject.all? { |d| d.class == ActiveSupport::TimeWithZone }).to be_truthy
    end
  end

  context ".folder_type_from" do
    subject { AppealRepository.folder_type_from(folder_record) }

    context "detects VBMS folder" do
      it { is_expected.to eq("VBMS") }
    end

    context "detects VVA folder" do
      let(:folder_record) { OpenStruct.new(tisubj2: "Y") }
      it { is_expected.to eq("VVA") }
    end

    context "detects paper" do
      let(:folder_record) { OpenStruct.new(tivbms: "other_val", tisubj2: "other_val") }
      it { is_expected.to eq("Paper") }
    end
  end

  context "#update_location_for_death_dismissal!" do
    let(:appeal) do
      create(:legacy_appeal, vacols_case: create(:case))
    end

    it "should end up in location 66" do
      LegacyAppeal.repository.update_location_for_death_dismissal!(appeal: appeal)
      appeal.case_record.reload
      refreshed_appeal = LegacyAppeal.find(appeal.id)
      final_location = LegacyAppeal::LOCATION_CODES[:sr_council_dvc]

      expect(appeal.case_record.bfcurloc).to eq(final_location)
      expect(refreshed_appeal.location_code).to eq(final_location)
    end
  end

  context "#location_after_dispatch" do
    let(:appeal) do
      create(:legacy_appeal, vacols_case: create(:case))
    end

    let(:special_issues) { {} }

    subject { AppealRepository.location_after_dispatch(appeal: appeal) }

    context "when appeal is inactive (in 'history status')" do
      let(:appeal) do
        create(:legacy_appeal, vacols_case: create(:case, :status_complete))
      end

      it { is_expected.to be_nil }
    end

    context "when appeal is a partial grant" do
      let(:appeal) do
        create(:legacy_appeal, vacols_case: create(:case, :status_remand, :disposition_allowed))
      end

      context "when no special issues" do
        it { is_expected.to eq("98") }
      end

      context "when vamc is true" do
        let(:appeal) do
          create(:legacy_appeal, vacols_case: create(:case), vamc: true)
        end
        it { is_expected.to eq("54") }
      end

      context "when national_cemetery_administration is true" do
        let(:appeal) do
          create(:legacy_appeal, vacols_case: create(:case), national_cemetery_administration: true)
        end
        it { is_expected.to eq("53") }
      end

      context "when a special issue besides vamc and national_cemetery_administration is true" do
        let(:appeal) do
          create(:legacy_appeal, vacols_case: create(:case), radiation: true)
        end
        it { is_expected.to eq("50") }
      end
    end

    context "remand" do
      let(:vacols_record) { :remand }

      context "when no special issues" do
        it { is_expected.to eq("98") }
      end
    end
  end

  context "#create_schedule_hearing_tasks" do
    context "when missing legacy appeals" do
      let!(:cases) { create_list(:case, 10, bfcurloc: "57", bfhr: "1") }

      it "creates the legacy appeal and creates schedule hearing tasks", skip: "flake on last expect" do
        AppealRepository.create_schedule_hearing_tasks

        expect(LegacyAppeal.all.pluck(:vacols_id)).to match_array(cases.pluck(:bfkey))
        expect(ScheduleHearingTask.all.pluck(:appeal_id)).to match_array(LegacyAppeal.all.pluck(:id))
        expect(ScheduleHearingTask.first.parent.type).to eq(HearingTask.name)
        expect(ScheduleHearingTask.first.parent.parent.type).to eq(RootTask.name)
        expect(VACOLS::Case.all.pluck(:bfcurloc).uniq).to eq([LegacyAppeal::LOCATION_CODES[:caseflow]])
      end
    end

    context "when some legacy appeals already have schedule hearing tasks" do
      let!(:cases) { create_list(:case, 5, bfcurloc: "57", bfhr: "1") }

      it "doesn't duplicate tasks" do
        AppealRepository.create_schedule_hearing_tasks

        more_cases = create_list(:case, 5, bfcurloc: "57", bfhr: "1")
        AppealRepository.create_schedule_hearing_tasks

        expect(LegacyAppeal.all.pluck(:vacols_id)).to match_array((cases + more_cases).pluck(:bfkey))
        expect(ScheduleHearingTask.all.pluck(:appeal_id)).to match_array(LegacyAppeal.all.pluck(:id))
      end
    end
  end

  context "#cases_that_need_hearings" do
    let!(:case_without_hearing) { create(:case, bfcurloc: "57", bfhr: "1") }
    let!(:case_with_closed_hearing) do
      create(
        :case,
        bfcurloc: "57",
        bfhr: "1",
        case_hearings: [create(:case_hearing, hearing_disp: "H")]
      )
    end
    let!(:case_with_open_hearing) do
      create(
        :case,
        bfcurloc: "57",
        bfhr: "1",
        case_hearings: [create(:case_hearing, hearing_disp: nil)]
      )
    end
    let!(:case_with_two_closed_hearings) do
      create(
        :case,
        bfcurloc: "57",
        bfhr: "1",
        case_hearings: create_list(:case_hearing, 2, hearing_disp: "H")
      )
    end
    let!(:case_with_two_open_hearings) do
      create(
        :case,
        bfcurloc: "57",
        bfhr: "1",
        case_hearings: create_list(:case_hearing, 2, hearing_disp: nil)
      )
    end

    it "excludes cases that have open hearings" do
      expect(AppealRepository.cases_that_need_hearings).to match_array(
        [
          case_without_hearing, case_with_closed_hearing, case_with_two_closed_hearings
        ]
      )
    end
  end

  describe ".find_case_record" do
    subject { AppealRepository.find_case_record(ids, ignore_misses: ignore_misses) }

    context "when input set of IDs includes records that have been deleted" do
      let(:retained_vacols_cases) { create_list(:case, 5) }
      let(:deleted_vacols_cases) { create_list(:case, 3) }
      let(:ids) { [retained_vacols_cases, deleted_vacols_cases].flatten.pluck(:bfkey) }

      before do
        deleted_vacols_cases.each(&:destroy!)
      end

      context "when the ignore_misses argument is set to true" do
        let(:ignore_misses) { true }
        it "returns only the elements which exist in the database" do
          found_case_records = subject
          expect(found_case_records.length).to eq(retained_vacols_cases.length)
          expect(found_case_records.pluck(:bfkey).sort).to eq(retained_vacols_cases.pluck(:bfkey).sort)
        end
      end

      context "when the ignore_misses argument is set to false" do
        let(:ignore_misses) { false }

        it "raises a record not found error" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
