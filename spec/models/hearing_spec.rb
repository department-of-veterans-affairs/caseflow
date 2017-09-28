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

  context "#to_hash_for_worksheet" do
    subject { hearing.to_hash_for_worksheet }

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
      let!(:issue1) { Generators::WorksheetIssue.create(appeal: appeal) }
      let!(:issue2) { Generators::WorksheetIssue.create(appeal: appeal) }

      it "should return issues through the appeal" do
        expect(subject["worksheet_issues"].size).to eq 2
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
        expect(subject["veteran_name"]).to eq(appeal.veteran_name)
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
        let(:appeal) { Appeal.create(vacols_id: "1234", vbms_id: "1234567") }

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

  context "#issues" do
    subject { hearing.worksheet_issues }
    let(:hearing) { Hearing.create(vacols_id: "3456") }

    context "when appeal is not set" do
      it { is_expected.to eq [] }
    end

    context "when appeal does not have any issues" do
      let(:appeal) { Appeal.create(vacols_id: "1234") }

      it { is_expected.to eq [] }
    end

    context "when appeal has issues" do
      let(:appeal) { Generators::Appeal.create(vacols_record: :remand_decided) }

      it "should create issues" do
        hearing.update(appeal: appeal)
        subject
        expect(subject.size).to eq 2
      end
    end
  end

  context ".create_from_vacols_record" do
    let(:vacols_record) do
      OpenStruct.new(hearing_pkseq: "1234", folder_nr: "5678", css_id: "1111")
    end
    let!(:user) { User.create(css_id: "1111", station_id: "123") }
    let!(:appeal) { Generators::Appeal.build(vacols_id: "5678") }

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
    let(:appeal) { Generators::Appeal.create(vacols_record: :form9_not_submitted) }
    let(:hearing) { Generators::Hearing.create(appeal: appeal) }

    context "when Vacols does not need an update" do
      let(:hearing_hash) do
        {
          military_service: "Vietnam 1968 - 1970",
          worksheet_issues_attributes: [
            {
              remand: true,
              vha: true,
              program: "Wheel",
              name: "Spoon",
              levels: %w(Cabbage Pickle),
              description: %w(Donkey Cow),
              from_vacols: true,
              vacols_sequence_id: 1
            }
          ]
        }
      end

      it "updates nested attributes (worksheet_issues)" do
        expect(hearing.worksheet_issues.count).to eq(0)
        subject # do update
        expect(hearing.worksheet_issues.count).to eq(1)

        issue = hearing.worksheet_issues.first
        expect(issue.remand).to eq true
        expect(issue.allow).to eq false
        expect(issue.deny).to eq false
        expect(issue.dismiss).to eq false
        expect(issue.vha).to eq true
        expect(issue.program).to eq "Wheel"
        expect(issue.name).to eq "Spoon"
        expect(issue.levels).to eq %w(Cabbage Pickle)
        expect(issue.description).to eq %w(Donkey Cow)

        # test that a 2nd save updates the same record, rather than create new one
        hearing_issue_id = hearing.worksheet_issues.first.id
        hearing_hash[:worksheet_issues_attributes][0][:deny] = true
        hearing_hash[:worksheet_issues_attributes][0][:description] = ["Tomato"]
        hearing_hash[:worksheet_issues_attributes][0][:id] = hearing_issue_id

        hearing.update(hearing_hash)

        issue = hearing.worksheet_issues.first

        expect(hearing.worksheet_issues.count).to eq(1)
        expect(issue.id).to eq(hearing_issue_id)
        expect(issue.deny).to eq(true)
        expect(issue.remand).to eq(true)
        expect(issue.allow).to eq(false)
        expect(issue.dismiss).to eq(false)
        expect(issue.program).to eq "Wheel"
        expect(issue.name).to eq "Spoon"
        expect(issue.levels).to eq %w(Cabbage Pickle)
        expect(issue.description).to eq ["Tomato"]

        # soft delete an issue
        hearing_hash[:worksheet_issues_attributes][0][:_destroy] = "1"
        hearing.update(hearing_hash)
        expect(hearing.worksheet_issues.count).to eq(0)
        expect(hearing.worksheet_issues.with_deleted.count).to eq(1)
        expect(hearing.worksheet_issues.with_deleted.first.deleted_at).to_not eq nil
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
