describe RampRefilingIntake do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:user) { Generators::User.build }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:veteran_file_number) { "64205555" }

  let(:intake) do
    RampRefilingIntake.new(
      user: user,
      veteran_file_number: veteran_file_number
    )
  end

  context "#start!" do
    subject { intake.start! }

    context "valid to start" do
      let!(:completed_ramp_election) do
        RampElection.create!(
          veteran_file_number: "64205555",
          notice_date: 3.days.ago,
          end_product_reference_id: "123"
        )
      end

      it "saves intake and sets detail to ramp election" do
        expect(subject).to be_truthy

        expect(intake.started_at).to eq(Time.zone.now)
        expect(intake.detail).to have_attributes(
          veteran_file_number: "64205555",
          ramp_election_id: completed_ramp_election.id
        )
      end
    end
  end

  context "#validate_start" do
    subject { intake.validate_start }

    context "there is not a completed ramp election for veteran" do
      let!(:completed_ramp_election) do
        RampElection.create!(
          veteran_file_number: "64205555",
          notice_date: 3.days.ago
        )
      end

      it "adds did_not_receive_ramp_election and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("no_complete_ramp_election")
      end
    end

    context "there is a completed ramp election for veteran" do
      let!(:completed_ramp_election) do
        RampElection.create!(
          veteran_file_number: "64205555",
          notice_date: 3.days.ago,
          end_product_reference_id: "123"
        )
      end

      it { is_expected.to eq(true) }
    end
  end
end
