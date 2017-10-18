describe Intake do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205050" }

  let(:detail) do
    RampElection.new(veteran_file_number: veteran_file_number, notice_date: Time.zone.now)
  end

  let(:user) { Generators::User.build }

  let(:intake) do
    Intake.new(veteran_file_number: veteran_file_number, detail: detail, user: user)
  end

  let!(:veteran) { Generators::Veteran.build(file_number: "64205050") }

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

  context "#complete!" do
    it "defaults to success" do
      intake.complete!
      expect(intake).to be_success
    end

    it "saves intake with proper tagging" do
      intake.complete!(:canceled)
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
        expect(intake.error_code).to eq(:invalid_file_number)
      end
    end

    context "veteran_file_number has less than 8 digits" do
      let(:veteran_file_number) { "1111222" }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq(:invalid_file_number)
      end
    end

    context "veteran_file_number has non-digit characters" do
      let(:veteran_file_number) { "HAXHAXHAX" }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq(:invalid_file_number)
      end
    end

    context "veteran not found in bgs" do
      let(:veteran_file_number) { "11111111" }

      it "adds veteran_not_found and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq(:veteran_not_found)
      end
    end

    context "veteran not accessible by user" do
      before do
        Fakes::BGSService.inaccessible_appeal_vbms_ids = [veteran_file_number]
      end

      it "adds veteran_not_accessible and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq(:veteran_not_accessible)
      end
    end

    context "when number is valid (even with extra spaces)" do
      let(:veteran_file_number) { "  64205050  " }
      it { is_expected.to be_truthy }
    end
  end
end
