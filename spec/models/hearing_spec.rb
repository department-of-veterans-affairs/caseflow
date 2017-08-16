describe Hearing do
  context ".update" do
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
