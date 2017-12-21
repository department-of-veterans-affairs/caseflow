describe RampRefilingIntake do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:user) { Generators::User.build }
  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number) }
  let(:detail) { nil }

  let(:intake) do
    RampRefilingIntake.new(
      user: user,
      veteran_file_number: veteran_file_number,
      detail: detail
    )
  end

  let(:completed_ramp_election) do
    RampElection.create!(
      veteran_file_number: veteran_file_number,
      notice_date: 3.days.ago,
      end_product_reference_id: Generators::EndProduct.build(
        veteran_file_number: veteran_file_number,
        bgs_attrs: { status_type_code: "CLR" }
      ).claim_id
    )
  end

  context "#start!" do
    subject { intake.start! }

    context "valid to start" do
      let!(:ramp_election) { completed_ramp_election }

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

    let!(:end_product) do
      Generators::EndProduct.build(
        veteran_file_number: "64205555",
        bgs_attrs: {
          status_type_code: end_product_status
        }
      )
    end

    let(:end_product_status) { "CLR" }

    context "there is not a completed ramp election for veteran" do
      let!(:not_complete_ramp_election) do
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
      let!(:ramp_election) do
        RampElection.create!(
          veteran_file_number: "64205555",
          notice_date: 3.days.ago,
          end_product_reference_id: end_product.claim_id
        )
      end

      context "the EP associated with original RampElection is still pending" do
        let(:end_product_status) { "PEND" }

        it "adds ramp_election_is_active and returns false" do
          expect(subject).to eq(false)
          expect(intake.error_code).to eq("ramp_election_is_active")
        end
      end

      context "the EP associated with original RampElection is closed" do
        it { is_expected.to eq(true) }
      end
    end
  end

  context "#cancel!" do
    subject { intake.cancel! }

    let(:detail) do
      RampRefiling.create!(
        ramp_election: completed_ramp_election,
        veteran_file_number: veteran_file_number
      )
    end

    it "cancels and deletes the refiling record created" do
      subject

      expect(intake.reload).to be_canceled
      expect { detail.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
