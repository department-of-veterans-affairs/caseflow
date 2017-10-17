describe RampIntake do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let(:user) { Generators::User.build }
  let(:detail) { nil }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:intake) do
    RampIntake.new(
      user: user,
      detail: detail,
      veteran_file_number: veteran_file_number
    )
  end

  context "#complete!" do
    subject { intake.complete! }

    let(:detail) do
      RampElection.create!(veteran_file_number: "64205555", notice_date: 5.days.ago)
    end

    let!(:appeals_to_close) do
      (1..2).map do
        Generators::Appeal.create(vbms_id: "64205555C", vacols_record: :ready_to_certify)
      end
    end

    it "closes out the appeals correctly" do
      expect(Fakes::AppealRepository).to receive(:close!).with(
        appeal: appeals_to_close.first,
        user: intake.user,
        closed_on: Time.zone.today,
        disposition_code: "P"
      )

      expect(Fakes::AppealRepository).to receive(:close!).with(
        appeal: appeals_to_close.last,
        user: intake.user,
        closed_on: Time.zone.today,
        disposition_code: "P"
      )

      subject
    end

    context "if VACOLS closure fails" do
      it "does not complete" do
        intake.save!
        expect(Fakes::AppealRepository).to receive(:close!).and_raise("VACOLS failz")

        expect { subject }.to raise_error("VACOLS failz")

        intake.reload
        expect(intake.completed_at).to be_nil
      end
    end
  end

  context "#start!" do
    subject { intake.start! }

    let!(:ramp_election) do
      RampElection.create!(veteran_file_number: "64205555", notice_date: 5.days.ago)
    end

    context "not valid to start" do
      let(:veteran_file_number) { "NOTVALID" }

      it "does not save intake and returns false" do
        expect(subject).to be_falsey
        expect(intake).to_not be_persisted
      end
    end

    context "valid to start" do
      it "saves intake and sets detail to ramp election" do
        expect(subject).to be_truthy

        expect(intake).to be_persisted
        expect(intake.started_at).to eq(Time.zone.now)
        expect(intake.detail).to eq(ramp_election)
      end
    end
  end

  context "#validate_start" do
    subject { intake.validate_start }

    context "there is not a ramp election for veteran" do
      it "adds did_not_receive_ramp_election and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq(:did_not_receive_ramp_election)
      end
    end

    context "there is a ramp election for veteran" do
      let!(:ramp_election) do
        RampElection.create!(veteran_file_number: "64205555", notice_date: 6.days.ago)
      end

      it { is_expected.to eq(true) }
    end
  end
end
