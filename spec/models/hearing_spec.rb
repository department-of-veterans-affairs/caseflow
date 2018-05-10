describe Hearing do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:hearing) do
    Generators::Hearing.build(
      date: date,
      disposition: disposition,
      hold_open: hold_open,
      type: type
    )
  end

  let(:date) { 1.day.ago }
  let(:disposition) { nil }
  let(:hold_open) { nil }
  let(:type) { :video }

  context "#location" do
    subject { hearing.location }

    it { is_expected.to eq("Baltimore regional office") }

    context "when it's a central office hearing" do
      let(:type) { :central_office }

      it { is_expected.to eq("Board of Veterans' Appeals in Washington, DC") }
    end
  end

  context "#no_show?" do
    subject { hearing.no_show? }
    let(:disposition) { :no_show }

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

    let(:appeal1) do
      Generators::Appeal.create(vacols_record: { template: :pending_hearing }, vbms_id: "123C")
    end
    let!(:appeal2) do
      Generators::Appeal.create(vacols_record: { template: :remand_decided }, vbms_id: "123C")
    end
    let!(:appeal3) do
      Generators::Appeal.create(vacols_record: { template: :full_grant_decided }, vbms_id: "123C")
    end
    let!(:appeal4) do
      Generators::Appeal.create(vacols_record: { template: :form9_not_submitted }, vbms_id: "123C")
    end
    let(:hearing) { Generators::Hearing.create(appeal_id: appeal1.id) }

    it "returns active appeals with no decision date and with form9 date" do
      expect(subject.size).to eq 3
    end

    it "returns snapshot appeals from postgres database even if changes happened in vacols" do
      expect(subject.size).to eq 3
      Fakes::AppealRepository.records.delete(appeal2.vacols_id)
      Fakes::AppealRepository.records.delete(appeal1.vacols_id)
      expect(subject.size).to eq 3
    end
  end

  context "#to_hash_for_worksheet" do
    subject { hearing.to_hash_for_worksheet(nil) }

    let(:appeal) do
      Generators::Appeal.create(vacols_record: { template: :pending_hearing },
                                vbms_id: "123C",
                                documents: documents)
    end
    let!(:additional_appeal) do
      Generators::Appeal.create(vacols_record: { template: :pending_hearing }, vbms_id: "123C")
    end
    let(:hearing) { Generators::Hearing.create(appeal: appeal) }
    let(:documents) do
      [Generators::Document.build(type: "NOD", received_at: 4.days.ago),
       Generators::Document.build(type: "SOC", received_at: 1.day.ago)]
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
        expect(subject["appellant_city"]).to eq(appeal.appellant_city)
        expect(subject["appellant_state"]).to eq(appeal.appellant_state)
        expect(subject["veteran_age"]).to eq(appeal.veteran_age)
        expect(subject["veteran_sex"]).to eq(appeal.veteran_sex)
        expect(subject["veteran_name"]).to eq(hearing.veteran_name)
        expect(subject["appellant_last_first_mi"]).to eq(hearing.appellant_last_first_mi)
        expect(subject["cached_number_of_documents"]).to eq 2
      end
    end
  end

  context "#military_service" do
    subject { hearing.military_service }
    let(:hearing) { Hearing.create(vacols_id: "3456", military_service: military_service) }

    context "when military service is not set" do
      let(:military_service) { nil }

      context "when appeal is not set" do
        it { is_expected.to eq nil }
      end

      context "when appeal is set" do
        let(:appeal) { Generators::Appeal.create(vacols_id: "1234", vbms_id: "1234567") }

        it "should load military service from appeal" do
          hearing.update(appeal: appeal)
          expect(subject).to eq appeal.veteran.periods_of_service.join("\n")
        end
      end
    end

    context "when military service is set" do
      let(:military_service) { "Test" }
      let(:appeal) { Appeal.create(vacols_id: "1234") }

      it "should load military service from appeal" do
        hearing.update(appeal: appeal)
        expect(subject).to eq "Test"
      end
    end
  end

  context ".current_issue_count" do
    subject { hearing.current_issue_count }
    let(:appeal1) { Generators::Appeal.create(vacols_record: { template: :pending_hearing }, vbms_id: "123C") }
    let!(:appeal2) { Generators::Appeal.create(vacols_record: { template: :pending_hearing }, vbms_id: "123C") }
    let(:hearing) { Generators::Hearing.create(appeal_id: appeal1.id) }
    it "should return the current hearing count from all active appeals" do
      expect(subject).to eq 2
    end
  end

  context ".assign_or_create_from_vacols_record" do
    let(:vacols_record) do
      OpenStruct.new(hearing_pkseq: "1234", folder_nr: "5678", css_id: "1111")
    end
    let!(:user) { User.create(css_id: "1111", station_id: "123") }
    let!(:appeal) { Generators::Appeal.build(vacols_id: "5678") }

    context "create vacols record" do
      subject { Hearing.assign_or_create_from_vacols_record(vacols_record) }

      it "should create a hearing record" do
        subject
        hearing = Hearing.find_by(vacols_id: "1234")
        expect(hearing.present?).to be true
        expect(hearing.appeal.vacols_id).to eq "5678"
        expect(hearing.user).to eq user
        expect(hearing.prepped).to be_falsey
      end
    end

    context "assign vacols record" do
      let(:vacols_record) do
        OpenStruct.new(hearing_pkseq: "1234", folder_nr: "5678", css_id: "1111")
      end

      let!(:existing_user) { User.create(css_id: vacols_record[:css_id], station_id: "123") }
      let!(:user) { User.create(css_id: "1112", station_id: "123") }
      let!(:hearing) { Hearing.create(vacols_id: "1234", user: user) }
      subject { Hearing.assign_or_create_from_vacols_record(vacols_record, hearing) }

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
    let(:hearing) { Generators::Hearing.create }

    context "when Vacols does not need an update" do
      let(:hearing_hash) do
        {
          military_service: "Vietnam 1968 - 1970",
          evidence: "Medical exam done on 10/10/2003",
          witness: "Jane Smith attended",
          contentions: "The veteran believes their neck is hurt",
          comments_for_attorney: "Look for neck-related records",
          prepped: true
        }
      end

      it "updates hearing columns" do
        subject
        expect(hearing.military_service).to eq "Vietnam 1968 - 1970"
        expect(hearing.evidence).to eq "Medical exam done on 10/10/2003"
        expect(hearing.witness).to eq "Jane Smith attended"
        expect(hearing.contentions).to eq "The veteran believes their neck is hurt"
        expect(hearing.comments_for_attorney).to eq "Look for neck-related records"
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
end
