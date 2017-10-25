describe RampIntake do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:notice_date) { 1.day.ago }
  let(:receipt_date) { 1.day.ago }
  let(:option_selected) { nil }

  let(:intake) do
    RampElection.new(
      veteran_file_number: veteran_file_number,
      notice_date: notice_date,
      option_selected: option_selected,
      receipt_date: receipt_date
    )
  end

  context "#valid?" do
    subject { intake.valid? }

    context "option_selected" do
      context "when saving receipt" do
        before { intake.start_saving_receipt }

        context "when it is set" do
          context "when it is a valid option" do
            let(:option_selected) { "higher_level_review_with_hearing" }
            it { is_expected.to be true }
          end
        end

        context "when it is nil" do
          it "adds error to receipt_date" do
            is_expected.to be false
            expect(intake.errors[:option_selected]).to include("blank")
          end
        end
      end
    end

    context "receipt_date" do
      context "when it is nil" do
        it { is_expected.to be true }
      end

      context "when it is after today" do
        let(:receipt_date) { 1.day.from_now }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(intake.errors[:receipt_date]).to include("in_future")
        end
      end

      context "when it is before notice_date" do
        let(:receipt_date) { 2.days.ago }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(intake.errors[:receipt_date]).to include("before_notice_date")
        end
      end

      context "when it is on or after notice date and on or before today" do
        let(:receipt_date) { 1.day.ago }
        it { is_expected.to be true }
      end

      context "when saving receipt" do
        before { intake.start_saving_receipt }

        context "when it is nil" do
          let(:receipt_date) { nil }

          it "adds error to receipt_date" do
            is_expected.to be false
            expect(intake.errors[:receipt_date]).to include("blank")
          end
        end
      end
    end
  end
end
