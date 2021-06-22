# frozen_string_literal: true

require_relative "appeal_shared_examples"

describe LegacyAppeal, :all_dbs do
  before do
    Timecop.freeze(post_ama_start_date)
  end

  let(:yesterday) { 1.day.ago.to_formatted_s(:short_date) }
  let(:twenty_days_ago) { 20.days.ago.to_formatted_s(:short_date) }
  let(:last_year) { 365.days.ago.to_formatted_s(:short_date) }
  let(:veteran_address) { nil }
  let(:appellant_address) { nil }
  let(:changed_hearing_request_type) { nil }

  let(:appeal) do
    create(
      :legacy_appeal,
      vacols_case: vacols_case,
      veteran_address: veteran_address,
      appellant_address: appellant_address,
      changed_hearing_request_type: changed_hearing_request_type
    )
  end

  context "includes PrintsTaskTree concern" do
    context "#structure" do
      let!(:root_task) { create(:root_task, appeal: appeal) }
      let(:vacols_case) { create(:case, bfcorlid: "123456789S") }

      subject { appeal.structure(:id) }

      it "returns the task structure" do
        expect_any_instance_of(RootTask).to receive(:structure).with(:id)
        expect(subject.key?(:"LegacyAppeal #{appeal.id} [id]")).to be_truthy
      end

      context "the appeal has more than one parentless task" do
        before { Colocated.singleton.add_user(create(:user)) }

        let!(:colocated_task) { create(:colocated_task, appeal: appeal, parent: nil) }

        it "returns all parentless tasks" do
          expect_any_instance_of(RootTask).to receive(:structure).with(:id)
          expect_any_instance_of(ColocatedTask).to receive(:structure).with(:id)
          expect(subject.key?(:"LegacyAppeal #{appeal.id} [id]")).to be_truthy
          expect(subject[:"LegacyAppeal #{appeal.id} [id]"].count).to eq 2
        end
      end
    end
  end

  describe "#activated?" do
    let(:vacols_case) { create(:case, case_status) }
    let(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

    subject { legacy_appeal.activated? }

    context "status is Active" do
      let(:case_status) { :status_active }

      it { is_expected.to eq(true) }
    end

    context "status is Motion" do
      let(:case_status) { :status_motion }

      it { is_expected.to eq(true) }
    end

    context "status is Complete" do
      let(:case_status) { :status_complete }

      it { is_expected.to eq(false) }
    end
  end

  describe "#veteran_file_number" do
    context "VACOLS has SSN as filenumber" do
      let(:ssn) { "123456789" }
      let(:file_number) { "12345678" }
      let!(:veteran) { create(:veteran, ssn: ssn, file_number: file_number) }
      let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "#{ssn}S")) }

      before do
        allow(DataDogService).to receive(:increment_counter) { @datadog_called = true }
      end

      it "prefers the Caseflow Veteran.file_number" do
        expect(legacy_appeal.veteran_file_number).to eq(file_number)
        expect(legacy_appeal.vbms_id).to eq("#{ssn}S")
        expect(legacy_appeal.sanitized_vbms_id).to eq(ssn)
        expect(legacy_appeal.veteran_file_number).to eq(legacy_appeal.veteran.file_number)
        expect(@datadog_called).to eq(true)
      end

      context "Veteran record has SSN value in file_number column" do
        before do
          veteran.update!(file_number: veteran.ssn)
          create(:veteran, ssn: ssn, file_number: file_number, participant_id: veteran.participant_id)
        end

        it "returns the file_number value from BGS" do
          expect(legacy_appeal.veteran_file_number).to eq(file_number)
          expect(legacy_appeal.veteran).to_not eq(veteran)
        end
      end
    end
  end

  context "#eligible_for_opt_in? and #matchable_to_request_issue?" do
    let(:receipt_date) { Date.new(2020, 4, 10) }
    let(:ama_date) { ama_start_date }
    let(:ineligible_soc_date) { receipt_date - 60.days - 1.day }
    let(:ineligible_nod_date) { receipt_date - 372.days - 1.day }
    let(:eligible_soc_date) { receipt_date - 60.days + 1.day }
    let(:eligible_nod_date) { receipt_date - 372.days + 1.day }

    let(:vacols_case) do
      create(:case, bfcorlid: "123456789S")
    end

    let(:issues) { [Generators::Issue.build(vacols_sequence_id: 1, disposition: nil)] }

    context "when the ssoc date is before when AMA was launched" do
      let(:receipt_date) { ama_date + 1.day }

      scenario "when the ssoc date is before AMA was launched" do
        allow(appeal).to receive(:active?).and_return(true)
        allow(appeal).to receive(:issues).and_return(issues)
        allow(appeal).to receive(:soc_date).and_return(ama_start_date - 5.days)

        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date)).to eq(false)
        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date, covid_flag: true)).to eq(false)
        expect(appeal.matchable_to_request_issue?(receipt_date: receipt_date)).to eq(true)
      end
    end

    context "checks ssoc/soc dates" do
      scenario "when is active but not eligible" do
        allow(appeal).to receive(:active?).and_return(true)
        allow(appeal).to receive(:issues).and_return(issues)
        allow(appeal).to receive(:soc_date).and_return(ineligible_soc_date - 3.days)
        allow(appeal).to receive(:nod_date).and_return(ineligible_nod_date)

        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date)).to eq(false)
        expect(appeal.matchable_to_request_issue?(receipt_date)).to eq(true)
      end
    end

    scenario "when is active and soc is not eligible but ssoc is" do
      allow(appeal).to receive(:active?).and_return(true)
      allow(appeal).to receive(:issues).and_return(issues)
      allow(appeal).to receive(:soc_date).and_return(ineligible_soc_date)
      allow(appeal).to receive(:ssoc_dates).and_return([eligible_soc_date])
      allow(appeal).to receive(:nod_date).and_return(ineligible_nod_date)

      expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date)).to eq(true)
      expect(appeal.matchable_to_request_issue?(receipt_date)).to eq(true)
    end

    scenario "when is not active but is eligible" do
      allow(appeal).to receive(:active?).and_return(false)
      allow(appeal).to receive(:issues).and_return(issues)
      allow(appeal).to receive(:soc_date).and_return(eligible_soc_date)
      allow(appeal).to receive(:nod_date).and_return(ineligible_nod_date)

      expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date)).to eq(true)
      expect(appeal.matchable_to_request_issue?(receipt_date)).to eq(true)
    end

    context "check ssoc/soc dates" do
      scenario "when is not active or eligible" do
        allow(appeal).to receive(:active?).and_return(false)
        allow(appeal).to receive(:issues).and_return(issues)
        allow(appeal).to receive(:soc_date).and_return(ineligible_soc_date - 3.days)
        allow(appeal).to receive(:nod_date).and_return(ineligible_nod_date)

        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date)).to eq(false)
        expect(appeal.matchable_to_request_issue?(receipt_date)).to eq(false)
      end
    end

    scenario "when is active or eligible but has no issues" do
      allow(appeal).to receive(:active?).and_return(true)
      allow(appeal).to receive(:issues).and_return([])
      allow(appeal).to receive(:soc_date).and_return(eligible_soc_date)
      allow(appeal).to receive(:nod_date).and_return(eligible_nod_date)

      expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date)).to eq(true)
      expect(appeal.matchable_to_request_issue?(receipt_date)).to eq(false)
    end

    context "receipt_date is nil" do
      let(:receipt_date) { nil }

      scenario "always returns false" do
        allow(appeal).to receive(:active?).and_return(false)
        allow(appeal).to receive(:issues).and_return(issues)
        allow(appeal).to receive(:soc_date).and_return(Time.zone.today)
        allow(appeal).to receive(:nod_date).and_return(Time.zone.today)

        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date)).to eq(false)
        expect(appeal.matchable_to_request_issue?(receipt_date)).to eq(false)
      end
    end

    context "when receipt_date falls on saturday" do
      let(:new_receipt_date) { eligible_soc_date + 60.days }

      scenario "return true" do
        allow(appeal).to receive(:soc_date).and_return(eligible_soc_date)
        expect(appeal.eligible_for_opt_in?(receipt_date: new_receipt_date)).to eq(true)
        expect(new_receipt_date.saturday?).to eq(true)
      end
    end

    context "when receipt_date falls on sunday" do
      let(:new_receipt_date) { eligible_soc_date + 61.days }

      scenario "return true" do
        allow(appeal).to receive(:soc_date).and_return(eligible_soc_date)
        expect(appeal.eligible_for_opt_in?(receipt_date: new_receipt_date)).to eq(true)
        expect(new_receipt_date.sunday?).to eq(true)
      end
    end

    context "when receipt date falls on a holiday" do
      let(:federal_holiday) { Date.new(2020, 5, 25) }
      let(:receipt_date) { federal_holiday + 1.day }

      scenario "return true" do
        allow(appeal).to receive(:soc_date).and_return(federal_holiday - 61.days)
        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date, covid_flag: false)).to eq(true)
        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date + 1.day, covid_flag: false)).to eq(false)
        expect(check_for_federal_holiday(federal_holiday)).to eq(true)
      end
    end

    context "when receipt date falls on inauguration day " do
      let(:inauguration_date) { Date.new(2021, 1, 20) }
      let(:receipt_date) { inauguration_date + 1.day }

      scenario "return true" do
        allow(appeal).to receive(:soc_date).and_return(inauguration_date - 61.days)
        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date, covid_flag: false)).to eq(true)
        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date + 1.day, covid_flag: false)).to eq(false)
        expect(receipt_date.sunday?).to eq(false)
      end
    end

    context "when allowing covid-related timeliness exemptions" do
      before { FeatureToggle.enable!(:covid_timeliness_exemption) }
      after { FeatureToggle.disable!(:covid_timeliness_exemption) }
      let(:soc_covid_eligible_date) { Constants::DATES["SOC_COVID_ELIGIBLE"].to_date }
      let(:nod_covid_eligible_date) { Constants::DATES["NOD_COVID_ELIGIBLE"].to_date }

      scenario "when NOD date is eligible with covid-related exemption" do
        allow(appeal).to receive(:active?).and_return(false)
        allow(appeal).to receive(:issues).and_return(issues)
        allow(appeal).to receive(:soc_date).and_return(soc_covid_eligible_date - 1.day)
        allow(appeal).to receive(:nod_date).and_return(nod_covid_eligible_date + 1.day)

        expect(appeal.matchable_to_request_issue?(receipt_date)).to eq(true)
        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date)).to eq(false)
        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date, covid_flag: true)).to eq(true)
      end

      scenario "when SOC date is only eligible with a covid-related extension" do
        allow(appeal).to receive(:active?).and_return(false)
        allow(appeal).to receive(:issues).and_return(issues)
        allow(appeal).to receive(:soc_date).and_return(soc_covid_eligible_date + 1.day)
        allow(appeal).to receive(:nod_date).and_return(nod_covid_eligible_date - 1.day)

        expect(appeal.matchable_to_request_issue?(receipt_date)).to eq(true)
        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date)).to eq(false)
        expect(appeal.eligible_for_opt_in?(receipt_date: receipt_date, covid_flag: true)).to eq(true)
      end
    end
  end

  context "#documents_with_type" do
    subject { appeal.documents_with_type(*type) }
    let(:documents) do
      [
        build(:document, type: "NOD", received_at: 7.days.ago),
        build(:document, type: "BVA Decision", received_at: 7.days.ago),
        build(:document, type: "BVA Decision", received_at: 6.days.ago),
        build(:document, type: "SSOC", received_at: 6.days.ago)
      ]
    end

    let(:vacols_case) do
      create(:case, documents: documents)
    end

    context "when 1 type is passed" do
      let(:type) { "BVA Decision" }
      it "returns right number of documents and type" do
        expect(subject.count).to eq(2)
        expect(subject.first.type).to eq(type)
      end
    end

    context "when 2 types are passed" do
      let(:type) { %w[NOD SSOC] }
      it "returns right number of documents and type" do
        expect(subject.count).to eq(2)
        expect(subject.first.type).to eq(type.first)
        expect(subject.last.type).to eq(type.last)
      end
    end
  end

  context "#attorney_case_reviews" do
    subject { appeal.attorney_case_reviews }

    let(:vacols_case) do
      create(:case, :assigned, decass_count: 1, user: create(:user), document_id: "02255-00000002")
    end
    let!(:decass1) { create(:decass, defolder: vacols_case.bfkey, dedocid: nil) }
    let!(:decass2) { create(:decass, defolder: vacols_case.bfkey, dedocid: "02255-00000002") }

    it "returns all documents associated with the case" do
      expect(subject.size).to eq 2
    end
  end

  context "#attorney_case_review" do
    subject { appeal.attorney_case_review }

    context "when there is a decass record" do
      let!(:vacols_case) { create(:case, :assigned, user: create(:user)) }

      it "searches through attorney case reviews table" do
        expect(AttorneyCaseReview).to receive(:find_by)
        subject
      end
    end

    context "when there is no decass record" do
      let!(:vacols_case) { create(:case) }

      it "does not search through attorney case reviews table" do
        expect(AttorneyCaseReview).to_not receive(:find_by)
        subject
      end
    end
  end

  context "#overtime" do
    let!(:vacols_case) { create(:case) }

    include_examples "toggle overtime"
  end

  context "#nod" do
    let(:vacols_case) do
      create(:case_with_nod)
    end

    subject { appeal.nod }
    it { is_expected.to have_attributes(type: "NOD", vacols_date: vacols_case.bfdnod) }

    context "when nod_date is nil" do
      let(:vacols_case) do
        create(:case)
      end
      it { is_expected.to be_nil }
    end
  end

  context "#soc" do
    let(:vacols_case) do
      create(:case_with_soc)
    end

    subject { appeal.soc }
    it { is_expected.to have_attributes(type: "SOC", vacols_date: vacols_case.bfdsoc) }

    context "when soc_date is nil" do
      let(:vacols_case) do
        create(:case)
      end
      let(:soc_date) { nil }
      it { is_expected.to be_nil }
    end
  end

  context "#form9" do
    let(:vacols_case) do
      create(:case_with_form_9)
    end

    subject { appeal.form9 }
    it { is_expected.to have_attributes(type: "Form 9", vacols_date: vacols_case.bfd19) }

    context "when form9_date is nil" do
      let(:vacols_case) do
        create(:case)
      end
      let(:form9_date) { nil }
      it { is_expected.to be_nil }
    end
  end

  context "#ssocs" do
    let(:vacols_case) do
      create(:case)
    end
    subject { appeal.ssocs }

    context "when there are no ssoc dates" do
      it { is_expected.to eq([]) }
    end

    context "when there are ssoc dates" do
      let(:vacols_case) do
        create(:case_with_ssoc)
      end

      it "returns array of ssoc documents" do
        expect(subject.first).to have_attributes(vacols_date: vacols_case.bfssoc1)
        expect(subject.last).to have_attributes(vacols_date: vacols_case.bfssoc2)
      end
    end
  end

  context "#form9_due_date" do
    subject { appeal.form9_due_date }

    context "when the notification date is within the last year" do
      let(:vacols_case) do
        create(:case_with_notification_date)
      end

      it { is_expected.to eq((vacols_case.bfdrodec + 1.year).to_date) }
    end

    context "when the notification date is older" do
      let(:vacols_case) do
        create(:case_with_notification_date, bfdrodec: 13.months.ago, bfdsoc: 1.day.ago)
      end

      it { is_expected.to eq((vacols_case.bfdsoc + 60.days).to_date) }
    end

    context "when missing notification date or soc date" do
      let(:vacols_case) do
        create(:case)
      end

      let(:soc_date) { nil }
      it { is_expected.to eq(nil) }
    end
  end

  context "#soc_opt_in_due_date" do
    subject { appeal.soc_opt_in_due_date }

    context "when is no soc" do
      let(:vacols_case) do
        create(:case)
      end

      let(:soc_date) { nil }
      it { is_expected.to eq(nil) }
    end

    context "when there is an soc" do
      let(:vacols_case) do
        create(:case, bfdsoc: 1.day.ago)
      end

      it { is_expected.to eq((vacols_case.bfdsoc + 60.days).to_date) }
    end

    context "when there are multiple socs" do
      let(:vacols_case) do
        create(:case, bfdsoc: 1.year.ago, bfssoc1: 6.months.ago, bfssoc2: 1.day.ago)
      end

      it { is_expected.to eq((vacols_case.bfssoc2 + 60.days).to_date) }
    end
  end

  context "#cavc_due_date" do
    subject { appeal.cavc_due_date }

    context "when there is no decision date" do
      let(:vacols_case) do
        create(:case)
      end

      it { is_expected.to eq(nil) }
    end

    context "when the case has a non-Board disposition" do
      let(:vacols_case) do
        create(:case, :disposition_ramp)
      end

      it { is_expected.to eq(nil) }
    end

    context "when there is a decision date" do
      let(:vacols_case) do
        create(:case, :status_complete, :disposition_allowed, bfddec: 30.days.ago)
      end

      it { is_expected.to eq(90.days.from_now.to_date) }
    end
  end

  context "#events" do
    let(:vacols_case) do
      create(:case_with_form_9)
    end

    subject { appeal.events }

    it "returns list of events" do
      expect(!subject.empty?).to be_truthy
      expect(subject.count { |event| event.type == :claim_decision } > 0).to be_truthy
      expect(subject.count { |event| event.type == :nod } > 0).to be_truthy
      expect(subject.count { |event| event.type == :soc } > 0).to be_truthy
      expect(subject.count { |event| event.type == :form9 } > 0).to be_truthy
    end
  end

  context "#veteran_ssn" do
    subject { appeal.veteran_ssn }

    context "when claim number is also ssn" do
      let(:vacols_case) do
        create(:case, bfcorlid: "228081153S")
      end

      it { is_expected.to eq "228081153" }
    end

    context "when claim number is not ssn" do
      let(:vacols_case) do
        create(:case, bfcorlid: "228081153C")
      end
      let(:appeal) { create(:legacy_appeal, :with_veteran, vacols_case: vacols_case) }

      it { is_expected.to eq appeal.veteran.ssn }
    end
  end

  context "#documents_match?" do
    subject { appeal.documents_match? }

    context "when there is an nod, soc, and form9 document matching the respective dates" do
      context "when there are no ssocs" do
        let(:vacols_case) do
          create(:case_with_form_9)
        end

        it { is_expected.to be_truthy }
      end

      context "when ssoc dates don't match" do
        let(:vacols_case) do
          create(:case_with_ssoc, bfssoc1: 2.days.ago, bfssoc2: 2.days.ago)
        end

        it { is_expected.to be_falsy }
      end

      context "when received_at is nil" do
        let(:ssoc_documents) do
          [
            build(:document, type: "SSOC", received_at: nil),
            build(:document, type: "SSOC", received_at: 1.month.ago)
          ]
        end
        let(:vacols_case) do
          create(:case_with_ssoc, ssoc_documents: ssoc_documents)
        end

        it { is_expected.to be_falsy }
      end

      context "and ssoc dates match" do
        let(:vacols_case) do
          create(:case_with_ssoc)
        end

        it { is_expected.to be_truthy }
      end
    end

    context "when the nod date is mismatched" do
      let(:nod_document) do
        [build(:document, type: "NOD", received_at: 1.day.ago)]
      end

      let(:vacols_case) do
        create(:case_with_ssoc, nod_document: nod_document)
      end

      it { is_expected.to be_falsy }
    end

    context "when the soc date is mismatched" do
      let(:soc_document) do
        [build(:document, type: "SOC", received_at: 1.day.ago)]
      end

      let(:vacols_case) do
        create(:case_with_ssoc, soc_document: soc_document)
      end

      it { is_expected.to be_falsy }
    end

    context "when the form9 date is mismatched" do
      let(:form9_document) do
        [build(:document, type: "Form9", received_at: 1.day.ago)]
      end

      let(:vacols_case) do
        create(:case_with_ssoc, form9_document: form9_document)
      end

      it { is_expected.to be_falsy }
    end

    context "when at least one ssoc doesn't match" do
      let(:vacols_case) do
        create(:case_with_ssoc, bfssoc1: 2.days.ago)
      end

      it { is_expected.to be_falsy }
    end

    context "when one of the dates is missing" do
      let(:vacols_case) do
        create(:case_with_ssoc, bfdnod: nil)
      end

      it { is_expected.to be_falsy }
    end
  end

  context "#serialized_decision_date" do
    let(:appeal) { LegacyAppeal.new(decision_date: decision_date) }
    subject { appeal.serialized_decision_date }

    context "when decision date is nil" do
      let(:decision_date) { nil }
      it { is_expected.to eq("") }
    end

    context "when decision date exists" do
      let(:decision_date) { Time.zone.local(2016, 9, 6) }
      it { is_expected.to eq("2016/09/06") }
    end
  end

  context "#number_of_documents" do
    let(:documents) do
      [build(:document, type: "NOD"),
       build(:document, type: "SOC"),
       build(:document, type: "SSOC")]
    end

    let(:vacols_case) do
      create(:case, documents: documents)
    end

    context "Number of documents from vbms" do
      subject { appeal.number_of_documents }

      it "should return number of documents" do
        expect(subject).to eq 3
      end
    end
  end

  context "#number_of_documents_after_certification" do
    let(:documents) do
      [build(:document, type: "NOD", received_at: 4.days.ago),
       build(:document, type: "SOC", received_at: 1.day.ago),
       build(:document, type: "SSOC", received_at: 5.days.ago)]
    end

    let(:vacols_case) do
      create(:case, :certified, documents: documents, certification_date: certification_date)
    end

    subject { appeal.number_of_documents_after_certification }

    context "when certification_date is nil" do
      let(:certification_date) { nil }

      it do
        documents.each { |document| document.update(file_number: appeal.sanitized_vbms_id) }
        is_expected.to eq 0
      end
    end

    context "when certification_date is set" do
      let(:certification_date) { 2.days.ago }

      it do
        documents.each { |document| document.update(file_number: appeal.sanitized_vbms_id) }
        is_expected.to eq 1
      end
    end
  end

  context "#in_location?" do
    let(:vacols_case) do
      create(:case, bfcurloc: location_code)
    end

    let(:location_code) { "96" }

    subject { appeal.in_location?(location) }
    let(:location) { :remand_returned_to_bva }

    context "when location is not recognized" do
      let(:location) { :never_never_land }

      it "raises error" do
        expect { subject }.to raise_error(LegacyAppeal::UnknownLocationError)
      end
    end

    context "when is in location" do
      it { is_expected.to be_truthy }
    end

    context "when is not in location" do
      let(:location_code) { "97" }
      it { is_expected.to be_falsey }
    end
  end

  context "#location_history" do
    let(:vacols_case) do
      create(:case).tap { |vcase| vcase.update_vacols_location!(first_location) }
    end

    let(:first_location) { "96" }
    let(:second_location) { "50" }
    let(:third_location) { "81" }

    before do
      # undo the global freeze at the top of this file.
      # since VACOLS sets time internally via Oracle it does not respect Timecop.
      Timecop.return

      vacols_case.update_vacols_location!(second_location)

      # small hesitation so date column sorts correctly
      sleep 1
      vacols_case.update_vacols_location!(third_location)
    end

    subject { appeal.location_history.map { |priloc| [priloc.assigned_at, priloc.location, priloc.assigned_by] } }

    let(:oracle_sysdate) { Time.zone.now.utc.to_date } # NOT Time.zone.now because we want to act like Oracle SYSDATE

    it "returns array of date, to_whom, by_whom" do
      expect(subject).to eq([
                              [oracle_sysdate, first_location, "DSUSER"],
                              [oracle_sysdate, second_location, "DSUSER"],
                              [oracle_sysdate, third_location, "DSUSER"]
                            ])
      expect(appeal.location_history.last.summary).to eq(location: third_location,
                                                         assigned_at: oracle_sysdate,
                                                         assigned_by: "DSUSER",
                                                         date_in: nil,
                                                         date_out: oracle_sysdate)
    end
  end

  context "#case_assignment_exists" do
    let(:vacols_case) do
      create(:case, :assigned)
    end

    subject { appeal.case_assignment_exists }

    it { is_expected.to be_truthy }
  end

  context ".find_or_create_by_vacols_id" do
    let!(:vacols_case) do
      create(:case, bfkey: "123C")
    end

    subject { LegacyAppeal.find_or_create_by_vacols_id("123C") }

    context "when no appeal exists for VACOLS id" do
      context "when no VACOLS data exists for that appeal" do
        let!(:vacols_case) {}

        it "raises ActiveRecord::RecordNotFound error" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when VACOLS data exists for that appeal" do
        it "saves and returns that appeal with updated VACOLS data loaded" do
          is_expected.to be_persisted
          expect(subject.vbms_id).to eq(vacols_case.bfcorlid)
        end
      end
    end

    context "when appeal with VACOLS id exists in the DB" do
      before { create(:legacy_appeal, vacols_id: "123C", vbms_id: "456VBMS") }

      context "when no VACOLS data exists for that appeal" do
        let!(:vacols_case) {}

        it "raises ActiveRecord::RecordNotFound error" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when VACOLS data exists for that appeal" do
        it "saves and returns that appeal with updated VACOLS data loaded" do
          expect(subject.reload.id).to_not be_nil
          expect(subject.vbms_id).to eq(vacols_case.bfcorlid)
        end
      end
    end

    context "sets the vacols_id" do
      before do
        allow_any_instance_of(LegacyAppeal).to receive(:save) {}
      end

      it do
        is_expected.to be_an_instance_of(LegacyAppeal)
        expect(subject.vacols_id).to eq("123C")
      end
    end

    it "persists in database" do
      expect(LegacyAppeal.find_by(vacols_id: subject.vacols_id)).to be_an_instance_of(LegacyAppeal)
    end
  end

  context ".close" do
    let(:vacols_case) do
      create(:case_with_nod)
    end
    let(:another_vacols_case) do
      create(:case_with_decision, :status_remand)
    end

    let(:issues) { [] }
    let(:appeal_with_decision) do
      create(:legacy_appeal, vacols_case: another_vacols_case)
    end
    let(:user) { Generators::User.build }
    let(:disposition) { "RAMP Opt-in" }

    before do
      RequestStore[:current_user] = user
    end

    context "when called with both appeal and appeals" do
      it "should raise error" do
        expect do
          LegacyAppeal.close(
            appeal: appeal,
            appeals: [appeal, appeal_with_decision],
            user: user,
            closed_on: 4.days.ago,
            disposition: disposition
          )
        end.to raise_error("Only pass either appeal or appeals")
      end
    end

    context "when multiple appeals" do
      let(:vacols_case_with_recent_nod) do
        create(:case_with_nod, bfdnod: 1.day.ago)
      end
      let(:appeal_with_nod_after_election_received) do
        create(:legacy_appeal, vacols_case: vacols_case_with_recent_nod)
      end

      it "closes each appeal" do
        LegacyAppeal.close(
          appeals: [appeal, appeal_with_decision, appeal_with_nod_after_election_received],
          user: user,
          closed_on: 4.days.ago,
          disposition: disposition
        )

        expect(vacols_case.reload.bfmpro).to eq("HIS")
        expect(another_vacols_case.reload.bfmpro).to eq("HIS")
        expect(vacols_case_with_recent_nod.reload.bfmpro).to eq("HIS")
      end
    end

    context "when just one appeal" do
      subject do
        LegacyAppeal.close(
          appeal: appeal,
          user: user,
          closed_on: 4.days.ago,
          disposition: disposition
        )
      end

      context "when disposition is not valid" do
        let(:disposition) { "I'm not a disposition" }

        it "should raise error" do
          expect { subject }.to raise_error(/Disposition/)
        end
      end

      context "when disposition is valid" do
        context "when appeal is not active" do
          let(:vacols_case) { create(:case_with_nod, :status_complete) }

          it "should raise error" do
            expect { subject }.to raise_error(/active/)
          end
        end

        context "when appeal is active and undecided" do
          it "closes the appeal in VACOLS" do
            subject

            expect(vacols_case.reload.bfmpro).to eq("HIS")
            expect(vacols_case.reload.bfdc).to eq("P")
            expect(vacols_case.folder.reload.timduser).to eq(user.regional_office)
          end
        end

        context "when appeal is a remand" do
          let(:vacols_case) do
            create(:case_with_decision, case_issues: [create(:case_issue, :disposition_allowed)])
          end

          it "closes the remand in VACOLS" do
            subject

            expect(vacols_case.reload.bfmpro).to eq("HIS")
            expect(vacols_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:closed])
          end
        end
      end
    end
  end

  context ".reopen" do
    subject do
      LegacyAppeal.reopen(
        appeals: [appeal, undecided_appeal],
        user: user,
        disposition: disposition
      )
    end
    let(:vacols_case) do
      create(:case_with_nod, :status_complete, :disposition_allowed)
    end
    let(:ramp_vacols_case) do
      create(:case_with_decision, :status_complete, :disposition_ramp, bfboard: "00")
    end

    let(:user) { Generators::User.build }
    let(:disposition) { "RAMP Opt-in" }

    let(:undecided_appeal) do
      create(:legacy_appeal, vacols_case: ramp_vacols_case)
    end

    context "with valid appeals" do
      let!(:followup_case) do
        create(
          :case,
          bfkey: "#{vacols_case.bfkey}#{Constants::VACOLS_DISPOSITIONS_BY_ID.key(disposition)}"
        )
      end

      before do
        RequestStore[:current_user] = user
        vacols_case.update_vacols_location!("50")
        vacols_case.update_vacols_location!(LegacyAppeal::LOCATION_CODES[:closed])
        vacols_case.reload

        ramp_vacols_case.update_vacols_location!("77")
        ramp_vacols_case.update_vacols_location!(LegacyAppeal::LOCATION_CODES[:closed])
        ramp_vacols_case.reload
      end

      it "reopens each appeal according to it's type" do
        subject

        expect(vacols_case.reload.bfmpro).to eq("REM")
        expect(ramp_vacols_case.reload.bfmpro).to eq("ADV")
      end
    end

    context "disposition doesn't exist" do
      let(:disposition) { "I'm not a disposition" }

      it "should raise error" do
        expect { subject }.to raise_error(/Disposition/)
      end
    end

    context "one of the non-remand appeals is active" do
      let(:vacols_case) do
        create(:case_with_nod, :status_active, :disposition_allowed)
      end

      it "should raise error" do
        expect { subject }.to raise_error("Only closed appeals can be reopened")
      end
    end
  end

  context "#certify!" do
    let(:vacols_case) { create(:case) }
    subject { appeal.certify! }

    context "when form8 for appeal exists in the DB" do
      before do
        @form8 = Form8.create(vacols_id: appeal.vacols_id)
        @certification = Certification.create(vacols_id: appeal.vacols_id, hearing_preference: "VIDEO")
      end

      it "certifies the appeal using AppealRepository" do
        expect { subject }.to_not raise_error
        expect(vacols_case.reload.bf41stat).to_not be_nil
      end

      it "uploads the correct form 8 using AppealRepository" do
        expect { subject }.to_not raise_error
        expect(Fakes::VBMSService.uploaded_form8.id).to eq(@form8.id)
        expect(Fakes::VBMSService.uploaded_form8_appeal).to eq(appeal)
      end
    end

    context "when a cancelled certification for an appeal already exists in the DB" do
      before do
        @form8 = Form8.create(vacols_id: appeal.vacols_id)
        @cancelled_certification = Certification.create!(
          vacols_id: appeal.vacols_id, hearing_preference: "SOME_INVALID_PREF"
        )
        CertificationCancellation.create!(
          certification_id: @cancelled_certification.id,
          cancellation_reason: "reason",
          email: "test@caseflow.gov"
        )
        @certification = Certification.create!(vacols_id: appeal.vacols_id, hearing_preference: "VIDEO")
      end

      it "certifies the correct appeal using AppealRepository" do
        expect { subject }.to_not raise_error
        expect(vacols_case.reload.bfhr).to eq(VACOLS::Case::HEARING_PREFERENCE_TYPES_V2[:VIDEO][:vacols_value])
      end
    end

    context "when form8 doesn't exist in the DB for appeal" do
      it "throws an error" do
        expect { subject }.to raise_error("No Form 8 found for appeal being certified")
      end
    end
  end

  context "#certified?" do
    context "when case has certification date" do
      let(:vacols_case) do
        create(:case, :certified, certification_date: 2.days.ago)
      end

      it "is true" do
        expect(appeal.certified?).to be_truthy
      end
    end

    context "when case doesn't have certification date" do
      let(:vacols_case) do
        create(:case)
      end

      it "is false" do
        expect(appeal.certified?).to be_falsy
      end
    end
  end

  context "#hearing_pending?" do
    subject { LegacyAppeal.new(hearing_requested: false, hearing_held: false) }

    it "determines whether an appeal is awaiting a hearing" do
      expect(subject.hearing_pending?).to be_falsy
      subject.hearing_requested = true
      expect(subject.hearing_pending?).to be_truthy
      subject.hearing_held = true
      expect(subject.hearing_pending?).to be_falsy
    end
  end

  context "#sanitized_vbms_id" do
    subject { LegacyAppeal.new(vbms_id: "123C") }

    it "left-pads case-number ids" do
      expect(subject.sanitized_vbms_id).to eq("00000123")
    end

    it "left-pads 7-digit case-number ids" do
      subject.vbms_id = "2923988C"
      expect(subject.sanitized_vbms_id).to eq("02923988")
    end

    it "doesn't left-pad social security ids" do
      subject.vbms_id = "123S"
      expect(subject.sanitized_vbms_id).to eq("123")
    end
  end

  context "#fetch_appeals_by_file_number" do
    subject { LegacyAppeal.fetch_appeals_by_file_number(file_number) }
    let!(:vacols_case) do
      create(:case, bfcorlid: "123456789S")
    end

    context "when passed with valid vbms id" do
      let(:file_number) { "123456789" }

      it "returns an appeal" do
        expect(subject.length).to eq(1)
        expect(subject[0].vbms_id).to eq("123456789S")
      end
    end

    context "when passed an invalid vbms id" do
      context "length greater than 9" do
        let(:file_number) { "1234567890" }

        it "raises ActiveRecord::RecordNotFound error" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "length less than 3" do
        let(:file_number) { "12" }

        it "raises ActiveRecord::RecordNotFound error" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  context ".convert_file_number_to_vacols" do
    subject { LegacyAppeal.convert_file_number_to_vacols(file_number) }

    context "for a file number with less than 9 digits" do
      context "with leading zeros" do
        let(:file_number) { "00001234" }
        it { is_expected.to eq("1234C") }
      end

      context "with no leading zeros" do
        let(:file_number) { "12345678" }
        it { is_expected.to eq("12345678C") }
      end
    end

    context "for a file number with 9 digits" do
      let(:file_number) { "123456789" }
      it { is_expected.to eq("123456789S") }

      context "with letters" do
        let(:file_number) { "12ABCSD34ASDASD56789S" }
        it { is_expected.to eq("123456789S") }
      end

      context "with leading zeros and letters" do
        let(:file_number) { "00123C00S9S" }
        it { is_expected.to eq("123009C") }
      end
    end

    context "for a file number with more than 9 digits" do
      let(:file_number) { "1234567890" }

      it "raises InvalidFileNumber error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidFileNumber)
      end
    end
  end

  context "#partial_grant_on_dispatch?" do
    let!(:vacols_case) do
      create(:case, :status_remand, case_issues: issues)
    end
    subject { appeal.partial_grant_on_dispatch? }

    context "when no allowed issues" do
      let(:issues) { [create(:case_issue, :disposition_remanded)] }

      it { is_expected.to be_falsey }
    end

    context "when the allowed issues are new material" do
      let(:issues) { [create(:case_issue, :disposition_allowed, :compensation)] }

      it { is_expected.to be_falsey }
    end

    context "when there's a mix of allowed and remanded issues" do
      let(:issues) do
        [
          create(:case_issue, :disposition_allowed, issprog: "02", isscode: "15", isslev1: "03", isslev2: "5252"),
          create(:case_issue, :disposition_remanded, issprog: "02", isscode: "15", isslev1: "03", isslev2: "5252")
        ]
      end

      it { is_expected.to be_truthy }
    end
  end

  context "#full_grant_on_dispatch?" do
    let(:issues) { [] }

    subject { appeal.full_grant_on_dispatch? }

    context "when status is Remand" do
      let!(:vacols_case) { create(:case, :status_remand) }
      it { is_expected.to be_falsey }
    end

    context "when status is Complete" do
      let!(:vacols_case) { create(:case, :status_complete, case_issues: issues) }

      context "when at least one issues is new-material allowed" do
        let(:issues) do
          [
            create(:case_issue, :disposition_allowed, :compensation),
            create(:case_issue, :disposition_denied)
          ]
        end
        it { is_expected.to be_falsey }
      end

      context "when at least one issue is not new-material allowed" do
        let(:issues) do
          [
            create(:case_issue, :disposition_allowed),
            create(:case_issue, :disposition_denied)
          ]
        end
        it { is_expected.to be_truthy }
      end
    end
  end

  context "#remand_on_dispatch?" do
    subject { appeal.remand_on_dispatch? }

    context "status is not remand" do
      let!(:vacols_case) { create(:case, :status_complete) }
      it { is_expected.to be false }
    end

    context "status is remand" do
      let!(:vacols_case) { create(:case, :status_remand, case_issues: issues) }

      context "contains at least one new-material allowed issue" do
        let(:issues) do
          [
            create(:case_issue, :disposition_allowed),
            create(:case_issue, :disposition_remanded)
          ]
        end

        it { is_expected.to be false }
      end

      context "contains no new-material allowed issues" do
        let(:issues) do
          [
            create(:case_issue, :disposition_allowed, :compensation),
            create(:case_issue, :disposition_remanded)
          ]
        end

        it { is_expected.to be true }
      end
    end
  end

  context "#decided_by_bva?" do
    subject { appeal.decided_by_bva? }

    context "when status is not Complete" do
      let!(:vacols_case) { create(:case, :status_remand, :disposition_remanded) }
      it { is_expected.to be false }
    end

    context "when status is Complete" do
      let!(:vacols_case) { create(:case, :status_complete, :disposition_remanded) }

      context "when disposition is a BVA disposition" do
        it { is_expected.to be true }
      end

      context "when disposition is not a BVA disposition" do
        let!(:vacols_case) { create(:case, :status_remand, :disposition_ramp) }
        it { is_expected.to be false }
      end
    end
  end

  context "#compensation_issues" do
    subject { appeal.compensation_issues }

    let!(:vacols_case) { create(:case, case_issues: issues) }
    let(:compensation_issue) do
      create(
        :case_issue, :disposition_allowed, :compensation
      )
    end
    let(:issues) do
      [
        compensation_issue,
        create(
          :case_issue, :disposition_allowed, :education
        )
      ]
    end

    it { expect(subject[0].vacols_sequence_id).to eq(compensation_issue.issseq) }
  end

  context "#compensation?" do
    subject { appeal.compensation? }

    let!(:vacols_case) { create(:case, case_issues: issues) }
    let(:compensation_issue) do
      create(
        :case_issue, :disposition_allowed, :compensation
      )
    end
    let(:education_issue) do
      create(
        :case_issue, :disposition_allowed, :education
      )
    end

    context "when there are no compensation issues" do
      let(:issues) { [education_issue] }
      it { is_expected.to be false }
    end

    context "when there is at least 1 compensation issue" do
      let(:issues) { [education_issue, compensation_issue] }
      it { is_expected.to be true }
    end
  end

  context "#fully_compensation?" do
    subject { appeal.fully_compensation? }

    let!(:vacols_case) { create(:case, case_issues: issues) }
    let(:compensation_issue) do
      create(
        :case_issue, :disposition_allowed, :compensation
      )
    end
    let(:education_issue) do
      create(
        :case_issue, :disposition_allowed, :education
      )
    end

    context "when there is at least one non-compensation issue" do
      let(:issues) { [education_issue, compensation_issue] }
      it { is_expected.to be false }
    end

    context "when there are all compensation issues" do
      let(:issues) { [compensation_issue] }
      it { is_expected.to be true }
    end
  end

  context "#eligible_for_ramp?" do
    subject { appeal.eligible_for_ramp? }

    let(:issues) { [create(:case_issue, :compensation)] }

    context "when reason for ineligibility" do
      let!(:vacols_case) { create(:case, :status_advance, bfcurloc: "96", case_issues: issues) }
      it { is_expected.to be_falsey }
    end

    context "when no reason for ineligibility" do
      let!(:vacols_case) { create(:case, :status_advance, bfcurloc: "90", case_issues: issues) }
      it { is_expected.to be_truthy }
    end
  end

  context "#ramp_ineligibility_reason" do
    subject { appeal.ramp_ineligibility_reason }

    let(:location_code) { nil }
    let(:issues) { [create(:case_issue, :compensation)] }

    context "if status is not advance or remand" do
      let(:docket_date) { "2016-01-01" }
      let(:hearing_code) { "4" }
      let(:type_code) { "6" }
      let(:aod) { nil }

      let!(:vacols_case) do
        create(:case, :status_active, (aod ? :aod : :type_original),
               bfd19: docket_date,
               bfha: hearing_code,
               bfac: type_code,
               case_issues: issues)
      end

      # As of October 2018, appeals are only eligible for RAMP if their status is advance or remand
      it { is_expected.to eq(:activated_to_bva) }

      context "when docket date is before 2016" do
        let(:docket_date) { "2015-12-31" }
        it { is_expected.to eq(:activated_to_bva) }
      end

      context "when a hearing was held" do
        let(:hearing_code) { "2" }
        it { is_expected.to eq(:activated_to_bva) }
      end

      context "when advance on docket" do
        let(:aod) { true }
        it { is_expected.to eq(:activated_to_bva) }
      end

      context "when CAVC" do
        let(:type_code) { "7" }
        it { is_expected.to eq(:activated_to_bva) }
      end

      context "when status is Active (ACT)" do
        let(:status) { "Active" }
        it { is_expected.to eq(:activated_to_bva) }
      end
    end

    context "status is remand" do
      let(:correspondent) { create(:correspondent) }
      let!(:vacols_case) { create(:case, :status_remand, correspondent: correspondent, case_issues: issues) }
      it { is_expected.to be_nil }

      context "when appellant is not the veteran" do
        let(:correspondent) do
          create(
            :correspondent,
            appellant_first_name: "David",
            appellant_middle_initial: "D",
            appellant_last_name: "Schwimmer"
          )
        end

        it { is_expected.to eq(:claimant_not_veteran) }
      end

      context "when no compensation issues" do
        let(:issues) { [create(:case_issue, :education)] }
        it { is_expected.to eq(:no_compensation_issues) }
      end
    end

    context "status is advance" do
      context "location is remand_returned_to_bva" do
        let!(:vacols_case) { create(:case, :status_advance, bfcurloc: "96", case_issues: issues) }
        it { is_expected.to eq(:activated_to_bva) }
      end

      context "location is not remand_returned_to_bva" do
        let!(:vacols_case) { create(:case, :status_advance, bfcurloc: "90", case_issues: issues) }
        it { is_expected.to be_nil }
      end
    end
  end

  context "#disposition_remand_priority" do
    subject { appeal.disposition_remand_priority }
    context "when disposition is allowed and one of the issues is remanded" do
      let(:issues) do
        [
          create(:case_issue, :disposition_remanded),
          create(:case_issue, :disposition_allowed)
        ]
      end
      let!(:vacols_case) { create(:case, :disposition_allowed, case_issues: issues) }
      it { is_expected.to eq("Remanded") }
    end

    context "when disposition is allowed and none of the issues are remanded" do
      let(:issues) do
        [
          create(:case_issue, :disposition_allowed),
          create(:case_issue, :disposition_allowed)
        ]
      end
      let!(:vacols_case) { create(:case, :disposition_allowed, case_issues: issues) }
      it { is_expected.to eq("Allowed") }
    end

    context "when disposition is not allowed" do
      let!(:vacols_case) { create(:case, :disposition_vacated, case_issues: []) }
      it { is_expected.to eq("Vacated") }
    end
  end

  context "#dispatch_decision_type" do
    subject { appeal.dispatch_decision_type }
    context "when it has a mix of allowed and granted issues" do
      let(:issues) do
        [
          create(:case_issue, :disposition_allowed),
          create(:case_issue, :disposition_remanded)
        ]
      end
      let!(:vacols_case) { create(:case, :status_remand, case_issues: issues) }
      it { is_expected.to eq("Partial Grant") }
    end

    context "when it has a non-new-material allowed issue" do
      let(:issues) { [create(:case_issue, :disposition_allowed)] }
      let!(:vacols_case) { create(:case, :status_complete, case_issues: issues) }
      it { is_expected.to eq("Full Grant") }
    end

    context "when it has a remanded issue" do
      let(:issues) { [create(:case_issue, :disposition_remanded)] }
      let!(:vacols_case) { create(:case, :status_remand, case_issues: issues) }
      it { is_expected.to eq("Remand") }
    end
  end

  context "#task_header" do
    let(:appeal) do
      LegacyAppeal.new(
        veteran_first_name: "Davy",
        veteran_middle_initial: "Q",
        veteran_last_name: "Crockett",
        vbms_id: "123"
      )
    end

    subject { appeal.task_header }

    it "returns the correct string" do
      expect(subject).to eq("&nbsp &#124; &nbsp Crockett, Davy, Q (123)")
    end
  end

  context "#outcoded_by_name" do
    let(:appeal) do
      LegacyAppeal.new(
        outcoder_last_name: "King",
        outcoder_middle_initial: "Q",
        outcoder_first_name: "Andrew"
      )
    end

    subject { appeal.outcoded_by_name }

    it "returns the correct string" do
      expect(subject).to eq("King, Andrew, Q")
    end
  end

  context "#station_key" do
    let(:appeal) do
      LegacyAppeal.new(
        veteran_first_name: "Davy",
        veteran_middle_initial: "Q",
        veteran_last_name: "Crockett",
        regional_office_key: regional_office_key
      )
    end

    subject { appeal.station_key }

    context "when regional office key is mapped to a station" do
      let(:regional_office_key) { "RO13" }
      it { is_expected.to eq("313") }
    end

    context "when regional office key is one of many mapped to a station" do
      let(:regional_office_key) { "RO16" }
      it { is_expected.to eq("316") }
    end

    context "when regional office key is not mapped to a station" do
      let(:regional_office_key) { "SO62" }
      it { is_expected.to be_nil }
    end
  end

  context "#decisions" do
    subject { appeal.decisions }
    let(:decision) do
      Document.new(received_at: Time.zone.now.to_date, type: "BVA Decision")
    end
    let(:old_decision) do
      Document.new(received_at: 5.days.ago.to_date, type: "BVA Decision")
    end
    let(:appeal) { LegacyAppeal.new(vbms_id: "123") }

    context "when only one decision" do
      before do
        allow(appeal).to receive(:documents).and_return([decision])
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq([decision]) }
    end

    context "when only one recent decision" do
      before do
        allow(appeal).to receive(:documents).and_return([decision, old_decision])
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq([decision]) }
    end

    context "when no recent decision" do
      before do
        allow(appeal).to receive(:documents).and_return([old_decision])
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq([]) }
    end

    context "when no decision_date on appeal" do
      before do
        appeal.decision_date = nil
      end

      it { is_expected.to eq([]) }
    end

    context "when there are two decisions of the same type" do
      let(:documents) { [decision, decision.clone] }

      before do
        allow(appeal).to receive(:documents).and_return(documents)
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq(documents) }
    end

    context "when there are two decisions of the different types" do
      let(:documents) do
        [
          decision,
          Document.new(type: "Remand BVA or CAVC", received_at: 1.day.ago)
        ]
      end

      before do
        allow(appeal).to receive(:documents).and_return(documents)
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq(documents) }
    end
  end

  context "#non_canceled_end_products_within_30_days" do
    let!(:vacols_case) { create(:case_with_decision, bfddec: 1.day.ago) }
    let(:result) { appeal.non_canceled_end_products_within_30_days }

    let!(:twenty_day_old_pending_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: twenty_days_ago,
          claim_type_code: "172GRANT",
          status_type_code: "PEND"
        }
      )
    end

    let!(:recent_cleared_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: yesterday,
          claim_type_code: "170RMD",
          status_type_code: "CLR"
        }
      )
    end

    let!(:recent_cancelled_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: yesterday,
          claim_type_code: "172BVAG",
          status_type_code: "CAN"
        }
      )
    end

    let!(:year_old_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: last_year,
          claim_type_code: "172BVAG",
          status_type_code: "CLR"
        }
      )
    end

    it "returns correct eps" do
      expect(result.length).to eq(2)

      expect(result.first.claim_type_code).to eq("172GRANT")
      expect(result.last.claim_type_code).to eq("170RMD")
    end
  end

  context "#special_issues?" do
    let(:appeal) { LegacyAppeal.new(vacols_id: "123", us_territory_claim_philippines: true) }
    subject { appeal.special_issues? }

    it "is true if any special issues exist" do
      expect(subject).to be_truthy
    end

    it "is false if no special issues exist" do
      appeal.update!(us_territory_claim_philippines: false)
      expect(subject).to be_falsy
    end
  end

  context "#pending_eps" do
    let!(:vacols_case) { create(:case_with_decision, bfddec: 1.day.ago) }

    let!(:pending_eps) do
      [
        Generators::EndProduct.build(
          veteran_file_number: appeal.sanitized_vbms_id,
          bgs_attrs: {
            claim_receive_date: twenty_days_ago,
            claim_type_code: "070BVAGR",
            end_product_type_code: "071",
            status_type_code: "PEND"
          }
        ),
        Generators::EndProduct.build(
          veteran_file_number: appeal.sanitized_vbms_id,
          bgs_attrs: {
            claim_receive_date: last_year,
            claim_type_code: "070BVAGRARC",
            end_product_type_code: "070",
            status_type_code: "PEND"
          }
        )
      ]
    end

    let!(:cancelled_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: yesterday,
          claim_type_code: "070RMND",
          end_product_type_code: "072",
          status_type_code: "CAN"
        }
      )
    end

    let!(:cleared_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: last_year,
          claim_type_code: "172BVAG",
          status_type_code: "CLR"
        }
      )
    end

    let(:result) { appeal.pending_eps }

    it "returns only pending eps" do
      expect(result.length).to eq(2)

      expect(result.first.claim_type_code).to eq("070BVAGR")
      expect(result.last.claim_type_code).to eq("070BVAGRARC")
    end
  end

  context "#special_issues" do
    let!(:vacols_case) { create(:case) }
    subject { appeal.special_issues }

    context "when no special issues are true" do
      it { is_expected.to eq([]) }
    end

    context "when one special issue is true" do
      let(:appeal) { LegacyAppeal.new(dic_death_or_accrued_benefits_united_states: true) }
      it { is_expected.to eq(["DIC - death, or accrued benefits - United States"]) }
    end

    context "when many special issues are true" do
      let(:appeal) do
        LegacyAppeal.new(
          foreign_claim_compensation_claims_dual_claims_appeals: true,
          vocational_rehab: true,
          education_gi_bill_dependents_educational_assistance_scholars: true,
          us_territory_claim_puerto_rico_and_virgin_islands: true
        )
      end

      it "has expected issues", :aggregate_failures do
        expect(subject.length).to eq(4)
        is_expected.to include("Foreign claim - compensation claims, dual claims, appeals")
        is_expected.to include("Vocational Rehabilitation and Employment")
        is_expected.to include(/Education - GI Bill, dependents educational assistance/)
        is_expected.to include("U.S. Territory claim - Puerto Rico and Virgin Islands")
      end
    end
  end

  context "#veteran" do
    let(:vacols_case) { create(:case) }
    subject { appeal.veteran }

    let(:veteran_record) do
      { file_number: appeal.sanitized_vbms_id, first_name: "Ed", last_name: "Merica", ptcpnt_id: "1234" }
    end

    before do
      Fakes::BGSService.store_veteran_record(appeal.sanitized_vbms_id, veteran_record)
    end

    it "returns veteran loaded with BGS values" do
      is_expected.to have_attributes(first_name: "Ed", last_name: "Merica")
    end
  end

  context "#power_of_attorney" do
    let(:vacols_case) { create(:case, :representative_american_legion) }
    subject { appeal.power_of_attorney }

    it "returns poa loaded with VACOLS values" do
      is_expected.to have_attributes(
        vacols_representative_type: "Service Organization",
        vacols_representative_name: "The American Legion"
      )
    end

    it "returns poa loaded with BGS values by default" do
      is_expected.to have_attributes(bgs_representative_type: "Attorney", bgs_representative_name: "Clarence Darrow")
    end

    context "appellant is not veteran" do
      before do
        allow(appeal).to receive(:veteran_file_number) { "no-such-file-number" }
        allow_any_instance_of(BGSService).to receive(:fetch_person_by_ssn).with(appellant_ssn) do
          { ptcpnt_id: appellant_pid, ssn_nbr: appellant_ssn }
        end
      end

      let(:vacols_case) { create(:case, :representative_american_legion, correspondent: correspondent) }
      let(:appellant_ssn) { "666001234" }
      let(:appellant_pid) { "1234" }
      let(:poa_pid) { "600153863" } # defined in Fakes::BGSService
      let(:correspondent) do
        create(
          :correspondent,
          appellant_first_name: "David",
          appellant_middle_initial: "D",
          appellant_last_name: "Schwimmer",
          ssn: appellant_ssn
        )
      end

      it "uses appellant to load BGS POA" do
        expect(appeal.power_of_attorney.bgs_representative_name).to eq "Clarence Darrow"
        expect(appeal.power_of_attorney.bgs_participant_id).to eq poa_pid
      end
    end

    context "#power_of_attorney.bgs_representative_address" do
      subject { appeal.power_of_attorney.bgs_representative_address }

      it "returns address if we are able to retrieve it" do
        is_expected.to include(
          address_line_1: "9999 MISSION ST",
          city: "SAN FRANCISCO",
          zip: "94103"
        )
      end
    end
  end

  context "#issue_categories" do
    let(:vacols_case) { create(:case, case_issues: issues) }
    subject { appeal.issue_categories }

    let(:issues) do
      [
        create(:case_issue, :disposition_allowed, issprog: "02", isscode: "01"),
        create(:case_issue, :disposition_allowed, issprog: "02", isscode: "02"),
        create(:case_issue, :disposition_allowed, issprog: "02", isscode: "01")
      ]
    end

    it "has expected issues", :aggregate_failures do
      is_expected.to include("02-01")
      is_expected.to include("02-02")
      is_expected.to_not include("02-03")
    end

    it "returns uniqued issue categories" do
      expect(subject.length).to eq(2)
    end
  end

  context "#worksheet_issues" do
    subject { appeal.worksheet_issues.size }

    context "when appeal does not have any Vacols issues" do
      let(:vacols_case) { create(:case, case_issues: []) }
      it { is_expected.to eq 0 }
    end

    context "when appeal has Vacols issues" do
      let(:vacols_case) do
        create(:case, case_issues: [create(:case_issue), create(:case_issue)])
      end
      it { is_expected.to eq 2 }
    end
  end

  context "#contested_claim" do
    subject { appeal.contested_claim }
    let(:vacols_case) { create(:case) }

    context "when there is no contesting claimant" do
      it { is_expected.to eq false }
    end

    context "when there is a contesting claimant" do
      let(:vacols_case) do
        vacols_c = create(:case)
        create(:representative, reptype: "C", repkey: vacols_c.bfkey)
        vacols_c
      end

      it { is_expected.to eq true }
    end
  end

  context "#update" do
    subject { appeal.update!(appeals_hash) }
    let(:vacols_case) { create(:case) }

    context "when Vacols does not need an update" do
      context "updating worksheet issues" do
        let(:appeals_hash) do
          { worksheet_issues_attributes: [{
            remand: true,
            omo: true,
            description: "Cabbage\nPickle",
            notes: "Donkey\nCow",
            from_vacols: true,
            vacols_sequence_id: 1
          }] }
        end

        it "updates worksheet issues and does not create a new version in paper trail" do
          expect(appeal.worksheet_issues.count).to eq(0)
          subject # do update
          expect(appeal.worksheet_issues.count).to eq(1)

          # Ensure paper trail is not updated after initial update
          expect(appeal.reload.versions.length).to eq(0)

          issue = appeal.worksheet_issues.first
          expect(issue.remand).to eq true
          expect(issue.allow).to eq false
          expect(issue.deny).to eq false
          expect(issue.dismiss).to eq false
          expect(issue.omo).to eq true
          expect(issue.description).to eq "Cabbage\nPickle"
          expect(issue.notes).to eq "Donkey\nCow"

          # test that a 2nd save updates the same record, rather than create new one
          id = appeal.worksheet_issues.first.id
          appeals_hash[:worksheet_issues_attributes][0][:deny] = true
          appeals_hash[:worksheet_issues_attributes][0][:notes] = "Tomato"
          appeals_hash[:worksheet_issues_attributes][0][:id] = id

          appeal.update(appeals_hash)

          # Ensure paper trail is not updated after additional update
          expect(appeal.reload.versions.length).to eq(0)

          expect(appeal.worksheet_issues.count).to eq(1)
          issue = appeal.worksheet_issues.first
          expect(issue.id).to eq(id)
          expect(issue.deny).to eq(true)
          expect(issue.remand).to eq(true)
          expect(issue.allow).to eq(false)
          expect(issue.dismiss).to eq(false)
          expect(issue.description).to eq "Cabbage\nPickle"
          expect(issue.notes).to eq "Tomato"

          # soft delete an issue
          appeals_hash[:worksheet_issues_attributes][0][:_destroy] = "1"
          appeal.update(appeals_hash)
          expect(appeal.worksheet_issues.count).to eq(0)
          expect(appeal.worksheet_issues.with_deleted.count).to eq(1)
          expect(appeal.worksheet_issues.with_deleted.first.deleted_at).to_not eq nil
        end
      end

      context "updating changed_hearing_request_type to valid value" do
        let(:appeals_hash) { { changed_hearing_request_type: "V" } }
        let(:updated_appeals_hash) { { changed_hearing_request_type: HearingDay::REQUEST_TYPES[:virtual] } }

        it "successfully updates" do
          subject
          expect(appeal.reload.changed_hearing_request_type).to eq(HearingDay::REQUEST_TYPES[:video])
        end

        it "creates a new version in paper trail" do
          subject

          # Check for the first round fo updates
          expect(appeal.reload.changed_hearing_request_type).to eq(HearingDay::REQUEST_TYPES[:video])
          expect(appeal.reload.versions.length).to eq(1)
          expect(appeal.reload.paper_trail.previous_version.changed_hearing_request_type).to eq(nil)

          # Check that changing the hearing request type creates a new paper trail record
          appeal.update(updated_appeals_hash)
          new_appeal = appeal.reload
          expect(new_appeal.versions.length).to eq(2)

          # Ensure the correct details are stored in paper trail
          changed_hearing_request_type = new_appeal.paper_trail.previous_version.changed_hearing_request_type
          expect(changed_hearing_request_type).to eq(HearingDay::REQUEST_TYPES[:video])

          # Ensure the previous version is set to the original appeal
          expect(new_appeal.paper_trail.previous_version).to eq(appeal)
        end
      end

      context "updating changed_hearing_request_type to invalid value" do
        let(:appeals_hash) { { changed_hearing_request_type: "INVALID" } }

        it "throws an exception" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end

  context "#appellant_last_first_mi" do
    let(:vacols_case) do
      create(:case, correspondent:
        create(
          :correspondent,
          appellant_first_name: "Joe",
          appellant_middle_initial: "E",
          appellant_last_name: "Tester"
        ))
    end
    subject { appeal.appellant_last_first_mi }
    it { is_expected.to eql("Tester, Joe E.") }

    context "when appellant has no first name" do
      let(:vacols_case) do
        create(:case, correspondent: create(:correspondent))
      end
      subject { appeal.appellant_last_first_mi }
      it { is_expected.to be_nil }
    end
  end

  context ".to_hash" do
    let(:vacols_case) do
      create(:case, :aod, :type_cavc_remand, bfregoff: "RO13", folder: create(:folder, tinum: "13 11-265"))
    end
    context "when issues parameter is nil and contains additional attributes" do
      subject { appeal.to_hash(viewed: true, issues: nil) }

      it "includes viewed boolean in hash" do
        expect(subject["viewed"]).to be_truthy
      end

      it "issues is null in hash" do
        expect(subject["issues"]).to be_nil
      end

      it "includes aod, cavc, regional_office and docket_number" do
        expect(subject["aod"]).to be_truthy
        expect(subject["cavc"]).to be_truthy
        expect(subject["regional_office"][:key]).to eq("RO13")
        expect(subject["docket_number"]).to eq("13 11-265")
      end
    end

    context "when issues and viewed attributes are provided" do
      subject { appeal.to_hash(viewed: true, issues: issues) }

      let!(:labels) do
        ["Compensation", "Service connection", "Other", "Left knee", "Right knee"]
      end

      let!(:issues) do
        [Generators::Issue.build(disposition: :allowed,
                                 codes: %w[02 15 03 04 05],
                                 labels: labels)]
      end

      it "includes viewed boolean in hash" do
        expect(subject["viewed"]).to be_truthy
      end

      it "includes issues in hash" do
        expect(subject["issues"]).to eq(issues.map(&:attributes))
      end
    end
  end

  context "#vbms_id" do
    let(:appeal) { LegacyAppeal.new(vacols_id: "12345", vbms_id: "6789") }
    context "when vbms_id exists in the caseflow DB" do
      it "does not make a request to VACOLS" do
        expect(appeal).to receive(:perform_vacols_request)
          .exactly(0).times

        expect(appeal.attributes["vbms_id"]).to_not be_nil
        expect(appeal.vbms_id).to_not be_nil
      end
    end

    context "when vbms_id is nil" do
      let(:vacols_case) { create(:case) }
      let(:no_vbms_id_appeal) { LegacyAppeal.new(vacols_id: vacols_case.bfkey) }

      context "when appeal is in the DB" do
        before { no_vbms_id_appeal.save! }

        it "looks up vbms_id in VACOLS and saves" do
          expect(no_vbms_id_appeal).to receive(:perform_vacols_request)
            .exactly(1).times.and_call_original

          expect(no_vbms_id_appeal.attributes["vbms_id"]).to be_nil
          expect(no_vbms_id_appeal.reload.vbms_id).to_not be_nil
        end
      end

      context "when appeal is not in the DB" do
        it "looks up vbms_id in VACOLS but does not save" do
          expect(no_vbms_id_appeal).to receive(:perform_vacols_request)
            .exactly(1).times.and_call_original

          expect(no_vbms_id_appeal.attributes["vbms_id"]).to be_nil
          expect(no_vbms_id_appeal.vbms_id).to_not be_nil
          expect(no_vbms_id_appeal).to_not be_persisted
        end
      end
    end
  end

  context "#save_to_legacy_appeals" do
    let :appeal do
      LegacyAppeal.create!(
        vacols_id: "1234"
      )
    end

    let :legacy_appeal do
      LegacyAppeal.find(appeal.id)
    end

    it "Creates a legacy_appeal when an appeal is created" do
      expect(legacy_appeal).to_not be_nil
      expect(legacy_appeal.attributes).to eq(appeal.attributes)
    end

    it "Updates a legacy_appeal when an appeal is updated" do
      appeal.update!(rice_compliance: true)
      expect(legacy_appeal.attributes).to eq(appeal.attributes)
    end
  end

  context "#outstanding_vacols_mail" do
    let(:vacols_case) { create(:case) }
    subject { appeal.outstanding_vacols_mail }
    let!(:outstanding_mail) do
      [
        create(:mail, mlfolder: vacols_case.bfkey, mltype: "02")
      ]
    end

    context "when no mail is outstanding" do
      it "returns mail with type 02" do
        expect(subject).to eq [{ outstanding: false, code: "02", description: "Congressional Interest" }]
      end
    end

    context "when mail is outstanding" do
      let(:vacols_case) { create(:case) }
      let!(:outstanding_mail) do
        [
          create(:mail, mlfolder: vacols_case.bfkey, mltype: "02"),
          create(:mail, mlfolder: vacols_case.bfkey, mltype: "05")
        ]
      end

      it "returns true" do
        expect(subject).to eq [
          { outstanding: false, code: "02", description: "Congressional Interest" },
          { outstanding: true, code: "05", description: "Evidence or Argument" }
        ]
      end
    end
  end

  context "#destroy_legacy_appeal" do
    let :appeal do
      LegacyAppeal.create!(
        id: 1,
        vacols_id: "1234"
      )
    end

    it "Destroys a legacy_appeal when an appeal is destroyed" do
      appeal.destroy!
      expect(LegacyAppeal.where(id: appeal.id)).to_not exist
    end
  end

  context "#aod" do
    let(:vacols_case) { create(:case, :aod) }
    subject { appeal.aod }

    it { is_expected.to be_truthy }
  end

  context "#remand_return_date" do
    let(:vacols_case) { create(:case, :status_active) }
    subject { appeal.remand_return_date }

    context "when the appeal is active" do
      it { is_expected.to eq(nil) }
    end
  end

  context "#cavc_decisions" do
    let(:vacols_case) { create(:case) }
    subject { appeal.cavc_decisions }

    let!(:cavc_decision) { Generators::CAVCDecision.build(appeal: appeal) }
    let!(:another_cavc_decision) { Generators::CAVCDecision.build(appeal: appeal) }

    it { is_expected.to eq([cavc_decision, another_cavc_decision]) }
  end

  context "#congressional_interest_addresses" do
    context "when mail has congressional interest type" do
      let(:congress_person) do
        create(:correspondent,
               snamef: "Henry",
               snamemi: "J",
               snamel: "Clay",
               stitle: "Rep.",
               saddrst1: "123 K St. NW",
               saddrst2: "Suite 456",
               saddrcty: "Washington",
               saddrstt: "DC",
               saddrcnty: nil,
               saddrzip: "20001")
      end
      let!(:mail) { create(:mail, mltype: "02", mlfolder: vacols_case.bfkey, mlcorkey: congress_person.stafkey) }
      let(:vacols_case) { create(:case) }

      it "returns the congress persons' address" do
        expect(appeal.congressional_interest_addresses).to eq(
          [
            {
              full_name: "Rep. Henry Clay PhD",
              address_line_1: "123 K St. NW",
              address_line_2: "Suite 456",
              city: "Washington",
              state: "DC",
              country: nil,
              zip: "20001"
            }
          ]
        )
      end
    end

    context "when mail has congressional interest type but no correspondent record" do
      let!(:mail) { create(:mail, mltype: "02", mlfolder: vacols_case.bfkey, mlcorkey: nil) }
      let(:vacols_case) { create(:case) }

      it "returns nil" do
        expect(appeal.congressional_interest_addresses).to eq([nil])
      end
    end
  end

  context "#claimant" do
    let(:correspondent) do
      create(:correspondent,
             snamef: "Bobby",
             snamemi: "F",
             snamel: "Veteran",
             ssalut: "")
    end
    let!(:representative) do
      create(:representative,
             repkey: vacols_case.bfkey,
             reptype: "A",
             repfirst: "Attorney",
             repmi: "B",
             replast: "Lawyer",
             repaddr1: "111 Magnolia St.",
             repaddr2: "Suite 222",
             repcity: "New York",
             repst: "NY",
             repzip: "10000")
    end
    let!(:vacols_case) { create(:case, correspondent: correspondent, bfso: "T") }
    let(:veteran_address) do
      {
        addrs_one_txt: "123 K St. NW",
        addrs_two_txt: "Suite 456",
        addrs_three_txt: nil,
        city_nm: "Washington",
        postal_cd: "DC",
        cntry_nm: nil,
        zip_prefix_nbr: "20001"
      }
    end

    context "when veteran is the appellant and addresses are included" do
      it "the veteran is returned with addresses" do
        expect(appeal.claimant).to eq(
          first_name: "Bobby",
          middle_name: "F",
          last_name: "Veteran",
          name_suffix: nil,
          address: {
            address_line_1: "123 K St. NW",
            address_line_2: "Suite 456",
            address_line_3: nil,
            city: "Washington",
            state: "DC",
            country: nil,
            zip: "20001"
          },
          representative: {
            name: "Attorney B Lawyer",
            type: "Attorney",
            code: "T",
            participant_id: "600153863",
            address: {
              address_line_1: "111 Magnolia St.",
              address_line_2: "Suite 222",
              city: "New York",
              state: "NY",
              zip: "10000"
            }
          }
        )
      end
    end

    context "when representative is returned from BGS" do
      before do
        RequestStore.store[:application] = "queue"
      end

      after do
        RequestStore.store[:application] = nil
      end

      it "the appellant is returned" do
        expect(appeal.claimant).to eq(
          first_name: "Bobby",
          middle_name: "F",
          last_name: "Veteran",
          name_suffix: nil,
          address: {
            address_line_1: "123 K St. NW",
            address_line_2: "Suite 456",
            address_line_3: nil,
            city: "Washington",
            state: "DC",
            country: nil,
            zip: "20001"
          },
          representative: {
            name: "Clarence Darrow",
            type: "Attorney",
            code: "T",
            participant_id: "600153863",
            address: {
              address_line_1: "9999 MISSION ST",
              address_line_2: "UBER",
              address_line_3: "APT 2",
              city: "SAN FRANCISCO",
              state: "CA",
              country: "USA",
              zip: "94103"
            }
          }
        )
      end
    end

    context "when veteran is not the appellant" do
      let(:correspondent) do
        create(:correspondent,
               snamef: "Bobby",
               snamemi: "F",
               snamel: "Veteran",
               sspare1: "Claimant",
               sspare2: "Tommy",
               sspare3: "G",
               ssn: "123456789")
      end
      let(:appellant_address) do
        {
          addrs_one_txt: "456 K St. NW",
          addrs_two_txt: "Suite 789",
          addrs_three_txt: nil,
          city_nm: "Washington",
          postal_cd: "DC",
          cntry_nm: nil,
          zip_prefix_nbr: "20001"
        }
      end

      it "the appellant is returned" do
        expect(appeal.claimant).to eq(
          first_name: "Tommy",
          middle_name: "G",
          last_name: "Claimant",
          name_suffix: nil,
          address: {
            address_line_1: "456 K St. NW",
            address_line_2: "Suite 789",
            address_line_3: nil,
            city: "Washington",
            state: "DC",
            country: nil,
            zip: "20001"
          },
          representative: {
            name: "Attorney B Lawyer",
            type: "Attorney",
            code: "T",
            participant_id: "600153863",
            address: {
              address_line_1: "111 Magnolia St.",
              address_line_2: "Suite 222",
              city: "New York",
              state: "NY",
              zip: "10000"
            }
          }
        )
      end
    end
  end

  context "#contested_claimants" do
    subject { appeal.contested_claimants }
    let!(:vacols_case) { create(:case, bfso: "L", bfcorkey: "CK439252") }
    let!(:representative) do
      create(:representative,
             repkey: repkey,
             repcorkey: repcorkey,
             reptype: "C",
             repso: "V",
             repfirst: "Contested",
             repmi: "H",
             replast: "Claimant",
             repaddr1: "123 Oak St.",
             repaddr2: "Suite 222",
             repcity: "New York",
             repst: "NY",
             repzip: "10000")
    end
    let(:result) do
      [
        {
          type: "Claimant",
          first_name: "Contested",
          middle_name: "H",
          last_name: "Claimant",
          name_suffix: nil,
          address: {
            address_line_1: "123 Oak St.",
            address_line_2: "Suite 222",
            city: "New York",
            state: "NY",
            zip: "10000"
          },
          representative: { code: "V", name: "Vietnam Veterans of America" }
        }
      ]
    end

    context "when there are contested claimants" do
      context "and representative is found by repkey" do
        let(:repkey) { vacols_case.bfkey }
        let(:repcorkey) { "CF99999" }

        it { is_expected.to eq(result) }
      end

      context "and representative is found by repcorkey" do
        let(:repkey) { "12345" }
        let(:repcorkey) { vacols_case.bfcorkey }

        it { is_expected.to eq(result) }
      end
    end
  end

  context "#contested_claimant_agents" do
    context "when there are contested claimant agents" do
      let!(:representative) do
        create(:representative,
               repkey: vacols_case.bfkey,
               reptype: "D",
               repfirst: "Contested",
               repmi: "H",
               replast: "Claimant",
               repaddr1: "123 Oak St.",
               repaddr2: "Suite 222",
               repcity: "New York",
               repst: "NY",
               repzip: "10000")
      end
      let!(:vacols_case) { create(:case, bfso: "L") }

      it "the contested claimant is returned" do
        expect(appeal.contested_claimant_agents).to eq([
                                                         {
                                                           type: "Attorney",
                                                           first_name: "Contested",
                                                           middle_name: "H",
                                                           last_name: "Claimant",
                                                           name_suffix: nil,
                                                           address: {
                                                             address_line_1: "123 Oak St.",
                                                             address_line_2: "Suite 222",
                                                             city: "New York",
                                                             state: "NY",
                                                             zip: "10000"
                                                           },
                                                           representative: { code: nil, name: nil }
                                                         }
                                                       ])
      end
    end
  end

  context "#cancel_open_caseflow_tasks!" do
    let(:vacols_case) { create(:case, bfcurloc: "CASEFLOW") }
    let(:vacols_case2) { create(:case, bfcurloc: "CASEFLOW") }
    let(:appeal2) { create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: vacols_case2) }
    let(:vacols_case3) { create(:case, bfcurloc: "CASEFLOW") }
    let(:appeal3) { create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: vacols_case3) }

    context "if there are no Caseflow tasks on the legacy appeal" do
      it "throws no errors" do
        expect { appeal.cancel_open_caseflow_tasks! }.not_to raise_error
      end
    end

    context "if there are Caseflow tasks on the legacy appeal" do
      context "multiple open caseflow tasks" do
        it "cancels all the open tasks" do
          appeal2.cancel_open_caseflow_tasks!

          expect(appeal2.tasks.open.count).to eq(0)
          expect(appeal2.tasks.closed.count).to eq(3)
          expect(appeal3.tasks.open.count).to eq(3)
        end

        context "when a note has instructions" do
          it "should append a note to the canceled tasks" do
            task = appeal2.tasks.first
            task.update(instructions: ["Existing instructions"])
            appeal2.cancel_open_caseflow_tasks!
            expect(task.reload.instructions)
              .to eq(["Existing instructions", "Task cancelled due to death dismissal"])
          end
        end
      end

      context "open and closed caseflow tasks" do
        it "doesn't affect the already closed tasks" do
          appeal3.root_task.update!(status: Constants.TASK_STATUSES.cancelled)
          original_closed_at = appeal3.root_task.closed_at

          appeal3.cancel_open_caseflow_tasks!

          expect(appeal3.root_task.closed_at).to eq(original_closed_at)
        end
      end
    end
  end

  context "#eligible_for_death_dismissal?" do
    let(:correspondent) { create(:correspondent, sfnod: 4.days.ago) }
    let(:vacols_case) { create(:case, correspondent: correspondent) }
    let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let(:colocated_user) { create(:user) }
    let(:attorney) { create(:user) }
    let(:colocated_admin) { create(:user) }
    let(:user) { colocated_admin }

    before do
      OrganizationsUser.make_user_admin(colocated_admin, Colocated.singleton)
      Colocated.singleton.add_user(colocated_user)
      User.authenticate!(user: colocated_admin)
    end

    subject { appeal.eligible_for_death_dismissal?(user) }

    context "an appeal has a notice of death" do
      context "it has open colocated tasks" do
        let!(:colocated_task) { create(:colocated_task, appeal: appeal, assigned_by: attorney) }
        context "user is colocated admin" do
          it "returns eligible" do
            expect(subject).to eq(true)
          end
        end

        context "user is not colocated admin" do
          let(:user) { colocated_user }
          it "returns not eligible" do
            expect(subject).to eq(false)
          end
        end
      end

      context "it has no open colocated tasks" do
        let!(:colocated_task) {}
        it "returns not eligible" do
          expect(subject).to eq(false)
        end
      end
    end

    context "an appeal has no final notice of death" do
      let!(:colocated_task) { create(:colocated_task, appeal: appeal, assigned_by: attorney) }
      let(:correspondent) { create(:correspondent) }

      it "returns not eligible" do
        expect(subject).to eq(false)
      end
    end
  end

  context "#assigned_to_location" do
    context "if the case is complete" do
      let!(:vacols_case) { create(:case, :status_complete) }

      it "returns nil" do
        expect(appeal.assigned_to_location).to eq(nil)
      end
    end

    context "if the case has not been worked in caseflow" do
      let(:location_code) { "96" }
      let!(:vacols_case) { create(:case, bfcurloc: location_code) }

      it "returns the location code" do
        expect(appeal.assigned_to_location).to eq(location_code)
      end
    end

    context "if the case has been worked in caseflow" do
      let!(:vacols_case) { create(:case, bfcurloc: "CASEFLOW") }

      it "if there are no active tasks it returns 'CASEFLOW' (fallback case)" do
        expect(appeal.assigned_to_location).to eq("CASEFLOW")
      end

      context "if the only active case is a RootTask" do
        let!(:root_task) { create(:root_task, appeal: appeal) }

        it "returns Case storage" do
          expect(appeal.assigned_to_location).to eq(COPY::CASE_LIST_TABLE_CASE_STORAGE_LABEL)
        end
      end

      context "if there are active TrackVeteranTask, TimedHoldTask, and RootTask" do
        let(:today) { Time.zone.today }
        let!(:root_task) { create(:root_task, :in_progress, appeal: appeal) }
        before do
          create(:track_veteran_task, :in_progress, parent: root_task, updated_at: today + 11)
          create(:timed_hold_task, :in_progress, parent: root_task, updated_at: today + 11)
        end

        describe "when there are no other tasks" do
          it "returns Case storage because it does not include nonactionable tasks in its determinations" do
            expect(appeal.assigned_to_location).to eq(COPY::CASE_LIST_TABLE_CASE_STORAGE_LABEL)
          end
        end

        describe "when there is an assigned actionable task" do
          let(:task_assignee) { create(:user) }
          let!(:task) do
            create(:colocated_task, :in_progress, assigned_to: task_assignee, parent: root_task)
          end

          it "returns the actionable task's label and does not include nonactionable tasks in its determinations" do
            expect(appeal.assigned_to_location).to(
              eq(task_assignee.css_id), appeal.structure_render(:id, :status, :assigned_to_id, :created_at, :updated_at)
            )
          end
        end
      end

      context "if there is an assignee" do
        context "if the most recent assignee is an organization" do
          let(:organization) { create(:organization) }
          let(:today) { Time.zone.today }

          before do
            organization_root_task = create(:root_task, appeal: appeal)
            create(:ama_task, assigned_to: organization, parent: organization_root_task)

            # These tasks are the most recently updated but should be ignored in the determination
            create(:track_veteran_task, :in_progress, appeal: appeal, updated_at: today + 10)
            create(:timed_hold_task, :in_progress, appeal: appeal, updated_at: today + 10)
          end

          it "it returns the organization name" do
            expect(appeal.assigned_to_location).to eq(organization.name)
          end
        end

        context "if the most recent assignee is not an organization" do
          let(:user) { create(:user) }

          before do
            user_root_task = create(:root_task, appeal: appeal)
            create(:ama_task, assigned_to: user, parent: user_root_task)
          end

          it "it returns the id" do
            expect(appeal.assigned_to_location).to eq(user.css_id)
          end
        end

        context "if the task is on hold but there isn't an assignee" do
          let(:pre_ama) { Date.new(2018, 1, 1) }

          before do
            on_hold_root = create(:root_task, appeal: appeal, updated_at: pre_ama - 1)
            create(:ama_task, :on_hold, parent: on_hold_root, updated_at: pre_ama + 1)
          end

          it "it returns something" do
            expect(appeal.assigned_to_location).not_to eq(nil)
          end
        end
      end
    end
  end

  context "#address" do
    let(:appeal) do
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: create(:case),
        veteran_address: veteran_address
      )
    end

    subject { appeal.address }

    context "when veteran is the appellant" do
      let(:veteran_address) do
        {
          addrs_one_txt: "123 K St. NW",
          addrs_two_txt: "Suite 456",
          addrs_three_txt: nil,
          city_nm: "Washington",
          postal_cd: "DC",
          cntry_nm: nil,
          zip_prefix_nbr: "20001",
          ptcpnt_addrs_type_nm: "Mailing"
        }
      end

      it "returns the veterans's address from BGS" do
        expect(subject).not_to eq(nil)
        expect(subject.address_line_1).to eq(veteran_address[:addrs_one_txt])
        expect(subject.address_line_2).to eq(veteran_address[:addrs_two_txt])
        expect(subject.address_line_3).to eq(veteran_address[:addrs_three_txt])
        expect(subject.city).to eq(veteran_address[:city_nm])
        expect(subject.state).to eq(veteran_address[:postal_cd])
        expect(subject.country).to eq(veteran_address[:country])
        expect(subject.zip).to eq(veteran_address[:zip_prefix_nbr])
      end
    end
  end

  context "#representatives" do
    context "when there is no VSO" do
      before do
        allow_any_instance_of(PowerOfAttorney).to receive(:bgs_participant_id).and_return(nil)
      end
      let!(:vso) do
        Vso.create(
          name: "Test VSO",
          url: "test-vso"
        )
      end
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

      it "does not return VSOs with nil participant_id" do
        expect(appeal.representatives).to eq([])
      end
    end
  end

  describe ".ready_for_bva_dispatch?" do
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

    subject { appeal.ready_for_bva_dispatch? }

    context "Legacy appeals do not go to BVA Dispatch via Caseflow" do
      it "should return false" do
        expect(subject).to eq(false)
      end
    end
  end

  describe "#latest_informal_hearing_presentation_task" do
    let(:appeal) { create(:legacy_appeal) }

    it_behaves_like "latest informal hearing presentation task"
  end

  describe "#assigned_to_acting_judge_as_judge?" do
    shared_examples "assumes user is the decision drafter" do
      it { is_expected.to be false }
    end

    shared_examples "assumes user is the decision signer" do
      it { is_expected.to be true }
    end

    let(:acting_judge) { create(:user, :with_vacols_acting_judge_record) }
    let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case, :assigned, user: acting_judge)) }

    subject { appeal.assigned_to_acting_judge_as_judge?(acting_judge) }

    context "when the attorney review process has happened outside of caseflow" do
      context "when a decision has not been written for the case" do
        it_behaves_like "assumes user is the decision drafter"
      end

      context "when a decision has been written for the case" do
        before { VACOLS::Decass.where(defolder: appeal.vacols_id).update_all(dedocid: "02255-00000002") }

        it_behaves_like "assumes user is the decision signer"
      end
    end

    context "when the attorney review process has happened within caseflow" do
      let(:created_at) { VACOLS::Decass.where(defolder: appeal.vacols_id).first.deadtim }
      let!(:case_review) { create(:attorney_case_review, task_id: "#{appeal.vacols_id}-#{created_at}") }

      context "when the user does not match the judge or attorney on the case review" do
        it_behaves_like "assumes user is the decision drafter"

        it "falls back to check the presence of a decision document" do
          expect_any_instance_of(VACOLS::CaseAssignment).to receive(:valid_document_id?).once
          subject
        end
      end

      context "when the user matches the attorney on the case review" do
        before do
          case_review.update!(attorney: acting_judge)
          expect_any_instance_of(VACOLS::CaseAssignment).not_to receive(:valid_document_id?)
        end

        it_behaves_like "assumes user is the decision drafter"
      end

      context "when the user matches the judge on the case review" do
        before do
          case_review.update!(reviewing_judge: acting_judge)
          expect_any_instance_of(VACOLS::CaseAssignment).not_to receive(:valid_document_id?)
        end

        it_behaves_like "assumes user is the decision signer"
      end
    end
  end

  describe "#completed_hearing_on_previous_appeal?" do
    context "when there are no hearings" do
      let(:vacols_case) { create(:case, bfcorlid: "12345") }
      subject { appeal.completed_hearing_on_previous_appeal? }

      it "returns false" do
        vacols_ids = VACOLS::Case.where(bfcorlid: appeal.vbms_id).pluck(:bfkey)
        hearings = HearingRepository.hearings_for_appeals(vacols_ids)
        expect(hearings).to eq({})
        expect(subject).to eq false
      end
    end
  end
end
