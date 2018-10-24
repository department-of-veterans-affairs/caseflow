describe SupplementalClaim do
  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:receipt_date) { nil }
  let(:benefit_type) { nil }
  let(:legacy_opt_in_approved) { nil }

  let(:supplemental_claim) do
    SupplementalClaim.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      benefit_type: benefit_type,
      legacy_opt_in_approved: legacy_opt_in_approved
    )
  end

  context "#valid?" do
    subject { supplemental_claim.valid? }

    context "radio option fields" do
      context "when saving review" do
        before { supplemental_claim.start_review! }

        context "when they are set" do
          let(:benefit_type) { "compensation" }
          let(:legacy_opt_in_approved) { false }
          let(:receipt_date) { 1.day.ago }

          it "is valid" do
            is_expected.to be true
          end
        end

        context "when they are nil" do
          it "adds errors" do
            is_expected.to be false
            expect(supplemental_claim.errors[:benefit_type]).to include("blank")
            expect(supplemental_claim.errors[:legacy_opt_in_approved]).to include("blank")
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
          expect(supplemental_claim.errors[:receipt_date]).to include("in_future")
        end
      end

      context "when it is before AMA begin date" do
        let(:receipt_date) { SupplementalClaim::AMA_BEGIN_DATE - 1 }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(supplemental_claim.errors[:receipt_date]).to include("before_ama")
        end
      end

      context "when saving receipt" do
        before { supplemental_claim.start_review! }

        context "when it is nil" do
          let(:receipt_date) { nil }

          it "adds error to receipt_date" do
            is_expected.to be false
            expect(supplemental_claim.errors[:receipt_date]).to include("blank")
          end
        end
      end
    end
  end
end
