describe Intake do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  class TestIntake < Intake; end
  class AnotherTestIntake < Intake; end

  let(:veteran_file_number) { "64205050" }

  let(:detail) do
    RampElection.new(veteran_file_number: veteran_file_number, notice_date: Time.zone.now)
  end

  let(:user) { Generators::User.build }
  let(:another_user) { Generators::User.build(full_name: "David Schwimmer") }

  let(:intake) do
    TestIntake.new(
      veteran_file_number: veteran_file_number,
      detail: detail,
      user: user,
      started_at: 15.minutes.ago
    )
  end

  let!(:veteran) { Generators::Veteran.build(file_number: "64205050") }

  context ".build" do
    subject { Intake.build(form_type: form_type, veteran_file_number: veteran_file_number, user: user) }

    context "when form_type is supported" do
      let(:form_type) { "ramp_election" }

      it { is_expected.to be_a(RampElectionIntake) }
      it { is_expected.to have_attributes(veteran_file_number: veteran_file_number, user: user) }
    end

    context "when form_type is not supported" do
      let(:form_type) { "not_a_real_form" }

      it "raises error" do
        expect { subject }.to raise_error(Intake::FormTypeNotSupported)
      end
    end
  end

  context ".in_progress" do
    subject { Intake.in_progress }

    let!(:not_started_intake) { intake }

    let!(:started_intake) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 15.minutes.ago
      )
    end

    let!(:completed_intake) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 10.minutes.ago,
        completed_at: 5.minutes.ago
      )
    end

    it "returns in progress intakes" do
      expect(subject).to include(started_intake)
      expect(subject).to_not include(not_started_intake, completed_intake)
    end
  end

  context "#complete_with_status!" do
    it "saves intake with proper tagging" do
      intake.complete_with_status!(:canceled)
      intake.reload

      expect(intake.completed_at).to eq(Time.zone.now)
      expect(intake).to be_canceled
    end
  end

  context "#validate_start" do
    subject { intake.validate_start }

    context "veteran_file_number is null" do
      let(:veteran_file_number) { nil }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("invalid_file_number")
      end
    end

    context "veteran_file_number has fewer than 8 digits" do
      let(:veteran_file_number) { "1234567" }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("invalid_file_number")
      end
    end

    context "veteran_file_number has more than 9 digits" do
      let(:veteran_file_number) { "1234567899" }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("invalid_file_number")
      end
    end

    context "veteran_file_number has non-digit characters" do
      let(:veteran_file_number) { "HAXHAXHAX" }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("invalid_file_number")
      end
    end

    context "veteran_file_number is VACOLS style" do
      let(:veteran_file_number) { "12341234C" }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("invalid_file_number")
      end
    end

    context "veteran not found in bgs" do
      let(:veteran_file_number) { "11111111" }

      it "adds veteran_not_found and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("veteran_not_found")
      end
    end

    context "veteran not accessible by user" do
      before do
        Fakes::BGSService.inaccessible_appeal_vbms_ids = [veteran_file_number]
      end

      it "adds veteran_not_accessible and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("veteran_not_accessible")
      end
    end

    context "duplicate in progress intake already exists" do
      let!(:other_intake) do
        TestIntake.create!(
          veteran_file_number: veteran_file_number,
          user: another_user,
          started_at: 15.minutes.ago
        )
      end

      it "adds veteran_not_accessible and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("duplicate_intake_in_progress")
        expect(intake.error_data).to eq(processed_by: "David Schwimmer")
      end
    end

    context "duplicate intake exists, but isn't in progress" do
      let!(:other_intake) do
        TestIntake.create!(
          veteran_file_number: veteran_file_number,
          user: another_user,
          started_at: 15.minutes.ago,
          completed_at: 10.minutes.ago
        )
      end

      it { is_expected.to be_truthy }
    end

    context "in progress intake exists on same file number, but not same type" do
      let!(:other_intake) do
        AnotherTestIntake.create!(
          veteran_file_number: veteran_file_number,
          user: another_user,
          started_at: 15.minutes.ago
        )
      end

      it { is_expected.to be_truthy }
    end

    context "in progress intake exists on same type, but not same file number" do
      let!(:other_intake) do
        TestIntake.create!(
          veteran_file_number: "22226666",
          user: another_user,
          started_at: 15.minutes.ago
        )
      end

      it { is_expected.to be_truthy }
    end

    context "when number is valid (even with extra spaces)" do
      let(:veteran_file_number) { "  64205050  " }
      it { is_expected.to be_truthy }
    end
  end
end
