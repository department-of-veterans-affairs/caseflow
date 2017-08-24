describe Hearing do
  context "#active_appeal_streams" do
    subject { hearing.active_appeal_streams }

    let(:appeal1) do
      Generators::Appeal.create(vacols_record: { template: :pending_hearing }, vbms_id: "123C")
    end
    let!(:appeal2) do
      Generators::Appeal.create(vacols_record: { template: :remand_decided }, vbms_id: "123C")
    end
    let!(:appeal3) do
      Generators::Appeal.create(vacols_record: { template: :pending_hearing }, vbms_id: "123C")
    end
    let!(:appeal4) do
      Generators::Appeal.create(vacols_record: { template: :form9_not_submitted }, vbms_id: "123C")
    end
    let(:hearing) { Generators::Hearing.create(appeal_id: appeal1.id) }

    it "returns active appeals with no decision date and with form9 date" do
      expect(subject.size).to eq 2
    end
  end

  context "#to_hash" do
    subject { hearing.to_hash }

    context "when appeal has issues" do
      let(:appeal) { Generators::Appeal.create }
      let(:hearing) { Generators::Hearing.create(appeal: appeal) }
      let!(:issue1) { Generators::Issue.create(appeal: appeal) }
      let!(:issue2) { Generators::Issue.create(appeal: appeal) }

      it "should return issues through the appeal" do
        expect(subject["issues"].size).to eq 2
      end
    end
  end

  context "#set_issues_from_appeal" do
    subject { hearing.set_issues_from_appeal }
    let(:hearing) { Hearing.create(vacols_id: "3456") }

    context "when appeal is not set" do
      it "should not create any issues" do
        subject
        expect(hearing.issues.size).to eq 0
      end
    end

    context "when appeal does not have any issues" do
      let(:appeal) { Appeal.create(vacols_id: "1234") }

      it "should not create any issues" do
        hearing.update(appeal: appeal)
        subject
        expect(hearing.issues.size).to eq 0
      end
    end

    context "when appeal has issues" do
      let(:appeal) { Appeal.create(vacols_id: "1234") }
      let!(:issue1) { Generators::Issue.create(appeal: appeal) }
      let!(:issue2) { Generators::Issue.create(appeal: appeal) }

      it "should not create any issues" do
        hearing.update(appeal: appeal)
        subject
        expect(hearing.issues.size).to eq 2
      end
    end
  end

  context ".create_from_vacols_record" do
    let(:vacols_record) do
      OpenStruct.new(hearing_pkseq: "1234", folder_nr: "5678", css_id: "1111")
    end
    let!(:user) { User.create(css_id: "1111", station_id: "123") }
    subject { Hearing.create_from_vacols_record(vacols_record) }

    it "should should create a hearing record" do
      subject
      hearing = Hearing.find_by(vacols_id: "1234")
      expect(hearing.present?).to be true
      expect(hearing.appeal.vacols_id).to eq "5678"
      expect(hearing.user).to eq user
    end
  end

  context "#update" do
    subject { hearing.update(hearing_hash) }
    let(:hearing) { Generators::Hearing.build }

    context "when Vacols does not need an update" do
      let(:issue) { hearing.appeal.issues.first }
      let(:hearing_hash) do
        {
          worksheet_military_service: "Vietnam 1968 - 1970",
          issues_attributes: [
            {
              remand: true,
              hearing_worksheet_vha: true
            }
          ]
        }
      end

      it "updates nested attributes (issues)" do
        expect(hearing.issues.count).to eq(0)
        subject # do update
        expect(hearing.issues.count).to eq(1)

        expect(hearing.issues.first.remand).to eq(true)
        expect(hearing.issues.first.allow).to eq(false)
        expect(hearing.issues.first.deny).to eq(false)
        expect(hearing.issues.first.dismiss).to eq(false)
        expect(hearing.issues.first.hearing_worksheet_vha).to be_truthy

        # test that a 2nd save updates the same record, rather than create new one
        hearing_issue_id = hearing.issues.first.id
        hearing_hash[:issues_attributes][0][:deny] = true
        hearing_hash[:issues_attributes][0][:id] = hearing_issue_id

        hearing.update(hearing_hash)

        expect(hearing.issues.count).to eq(1)
        expect(hearing.issues.first.id).to eq(hearing_issue_id)
        expect(hearing.issues.first.deny).to eq(true)
        expect(hearing.issues.first.remand).to eq(true)
        expect(hearing.issues.first.allow).to eq(false)
        expect(hearing.issues.first.dismiss).to eq(false)
      end
    end

    context "when Vacols needs an update" do
      let(:hearing_hash) do
        { notes: "test notes",
          aod: :granted,
          transcript_requested: false,
          disposition: :postponed,
          hold_open: 60
        }
      end

      it "updates vacols hearing" do
        expect(hearing.notes).to eq nil
        expect(hearing.aod).to eq nil
        expect(hearing.transcript_requested).to eq nil
        expect(hearing.disposition).to eq nil
        expect(hearing.hold_open).to eq nil
        subject
        expect(hearing.notes).to eq "test notes"
        expect(hearing.aod).to eq :granted
        expect(hearing.transcript_requested).to eq false
        expect(hearing.disposition).to eq :postponed
        expect(hearing.hold_open).to eq 60
      end
    end
  end
end
