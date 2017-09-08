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

  context "#to_hash_with_appeals_and_issues" do
    subject { hearing.to_hash_with_appeals_and_issues }

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

    context "when appeal has issues" do
      let!(:issue1) { Generators::Issue.create(appeal: appeal) }
      let!(:issue2) { Generators::Issue.create(appeal: appeal) }

      it "should return issues through the appeal" do
        # there are 3 issues associated with the appeal
        # 1 issue is created in Generators::Appeal pending_hearing template
        # 2 issues are created above
        expect(subject["issues"].size).to eq 3
      end
    end

    context "when hearing has appeals ready for hearing" do
      it "should contain appeal streams" do
        expect(subject["appeals_ready_for_hearing"].size).to eq 2
      end
    end

    context "when a hearing & appeal exist" do
      it "returns expected keys" do
        expect(subject["appellant_city"]).to eq(appeal.appellant_city)
        expect(subject["appellant_state"]).to eq(appeal.appellant_state)
        expect(subject["veteran_age"]).to eq(appeal.veteran_age)
        expect(subject["veteran_full_name"]).to eq(appeal.veteran_full_name)
        expect(subject["cached_number_of_documents"]).to eq 2
        expect(subject["cached_number_of_documents_after_certification"]).to eq 0
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
          military_service: "Vietnam 1968 - 1970",
          issues_attributes: [
            {
              remand: true,
              vha: true
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
        expect(hearing.issues.first.vha).to be_truthy

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
          add_on: true,
          hold_open: 60,
          representative_name: "DAV - DON REED"
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
        expect(hearing.add_on).to eq true
        expect(hearing.hold_open).to eq 60
        expect(hearing.representative_name).to eq "DAV - DON REED"
      end
    end
  end
end
