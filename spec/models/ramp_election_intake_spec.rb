describe RampElectionIntake do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let(:user) { Generators::User.build }
  let(:detail) { nil }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:appeal_vacols_record) { :ready_to_certify }

  let(:intake) do
    RampElectionIntake.new(
      user: user,
      detail: detail,
      veteran_file_number: veteran_file_number
    )
  end

  let(:appeal) do
    Generators::Appeal.build(
      vbms_id: "64205555C",
      vacols_record: appeal_vacols_record,
      veteran: veteran
    )
  end

  context "#cancel!" do
    subject { intake.cancel! }

    let(:detail) do
      RampElection.create!(
        veteran_file_number: "64205555",
        notice_date: 5.days.ago,
        option_selected: "supplemental_claim",
        receipt_date: 3.days.ago
      )
    end

    it "cancels and clears detail values" do
      subject

      expect(intake.reload).to be_canceled
      expect(detail.reload).to have_attributes(
        option_selected: nil,
        receipt_date: nil
      )
    end
  end

  context "#complete!" do
    subject { intake.complete!({}) }

    let(:detail) do
      RampElection.create!(
        veteran_file_number: "64205555",
        notice_date: 5.days.ago,
        option_selected: "supplemental_claim",
        receipt_date: 3.days.ago
      )
    end

    let!(:appeals_to_close) do
      (1..2).map do
        Generators::Appeal.create(vbms_id: "64205555C", vacols_record: :ready_to_certify)
      end
    end

    it "closes out the appeals correctly and creates an end product" do
      expect(Fakes::VBMSService).to receive(:establish_claim!).and_call_original

      expect(Fakes::AppealRepository).to receive(:close_undecided_appeal!).with(
        appeal: appeals_to_close.first,
        user: intake.user,
        closed_on: Time.zone.today,
        disposition_code: "P"
      )

      expect(Fakes::AppealRepository).to receive(:close_undecided_appeal!).with(
        appeal: appeals_to_close.last,
        user: intake.user,
        closed_on: Time.zone.today,
        disposition_code: "P"
      )

      subject

      expect(intake.reload).to be_success
    end

    context "if VACOLS closure fails" do
      it "does not complete" do
        intake.save!
        expect(Fakes::AppealRepository).to receive(:close_undecided_appeal!).and_raise("VACOLS failz")

        expect { subject }.to raise_error("VACOLS failz")

        intake.reload
        expect(intake.completed_at).to be_nil
      end
    end
  end

  context "#serialized_appeal_issues" do
    subject { intake.serialized_appeal_issues }

    let!(:appeals) do
      [
        Generators::Appeal.create(
          vbms_id: "64205555C",
          issues: [
            Generators::Issue.build(note: "Broken thigh"),
            Generators::Issue.build(codes: %w[02 16 03 5252],
                                    labels: [
                                      "Compensation",
                                      "Something else",
                                      "All Others",
                                      "Knee, limitation of flexion of"
                                    ],
                                    note: "Broken knee")
          ]
        ),
        Generators::Appeal.create(
          vbms_id: "64205555C",
          issues: [
            Generators::Issue.build(codes: %w[02 15],
                                    labels: ["Compensation", "Last Issue"],
                                    note: "")
          ]
        )
      ]
    end

    it do
      is_expected.to eq([{
                          id: appeals.first.id,
                          issues: [{
                            program_description: "02 - Compensation",
                            description: [
                              "15 - Service connection",
                              "03 - All Others",
                              "5252 - Thigh, limitation of flexion of"
                            ],
                            note: "Broken thigh"
                          }, {
                            program_description: "02 - Compensation",
                            description: [
                              "16 - Something else",
                              "03 - All Others",
                              "5252 - Knee, limitation of flexion of"
                            ],
                            note: "Broken knee"
                          }]
                        },
                         {
                           id: appeals.last.id,
                           issues: [{
                             program_description: "02 - Compensation",
                             description: ["15 - Last Issue"],
                             note: ""
                           }]
                         }])
    end
  end

  context "#start!" do
    subject { intake.start! }
    let!(:ramp_appeal) { appeal }

    context "not valid to start" do
      let(:veteran_file_number) { "NOTVALID" }

      it "does not save intake and returns false" do
        expect(subject).to be_falsey

        expect(intake).to have_attributes(
          started_at: Time.zone.now,
          completed_at: Time.zone.now,
          completion_status: "error",
          error_code: "invalid_file_number",
          detail: nil
        )
      end
    end

    context "valid to start" do
      context "RAMP election with notice_date exists" do
        let!(:ramp_election) do
          RampElection.create!(veteran_file_number: "64205555", notice_date: 5.days.ago)
        end

        it "saves intake and sets detail to ramp election" do
          expect(subject).to be_truthy

          expect(intake.started_at).to eq(Time.zone.now)
          expect(intake.detail).to eq(ramp_election)
        end
      end

      context "matching RAMP election does not exist" do
        let(:ramp_election) { RampElection.where(veteran_file_number: "64205555").first }

        it "creates a new RAMP election with no notice_date" do
          expect(subject).to be_truthy

          expect(ramp_election).to_not be_nil
          expect(ramp_election.notice_date).to be_nil
        end
      end
    end
  end

  context "#validate_start" do
    subject { intake.validate_start }
    let!(:ramp_appeal) { appeal }

    let!(:ramp_election) do
      RampElection.create!(veteran_file_number: "64205555", notice_date: 6.days.ago)
    end

    context "the ramp election is complete" do
      let!(:complete_intake) do
        RampElectionIntake.create!(
          user: user,
          detail: ramp_election,
          completed_at: Time.zone.now,
          completion_status: :success
        )
      end

      it "adds ramp_election_already_complete and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("ramp_election_already_complete")
      end
    end

    context "there are no active appeals" do
      let(:appeal_vacols_record) { :full_grant_decided }

      it "adds no_eligible_appeals and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("no_active_appeals")
      end
    end

    context "there are eligible appeals" do
      it { is_expected.to eq(true) }
    end
  end
end
