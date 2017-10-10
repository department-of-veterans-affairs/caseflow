describe RampIntake do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let(:user) { Generators::User.build }
  let(:intake) { RampIntake.new(user: user, veteran_file_number: veteran_file_number) }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }

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

  context "#valid_to_start?" do
    subject { intake.valid_to_start? }

    context "there is not a ramp election for veteran" do
      it "adds didnt_receive_ramp_election and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq(:didnt_receive_ramp_election)
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
