describe HigherLevelReview do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:receipt_date) { nil }
  let(:informal_conference) { nil }
  let(:same_office) { nil }
  let(:end_product_reference_id) { nil }
  let(:established_at) { nil }
  let(:end_product_status) { nil }

  let(:higher_level_review) do
    HigherLevelReview.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      informal_conference: informal_conference,
      same_office: same_office,
      end_product_reference_id: end_product_reference_id,
      established_at: established_at,
      end_product_status: end_product_status
    )
  end

  context "#valid?" do
    subject { supplemental_claim.valid? }

    context "informal_conference" do
      context "when saving review" do
        before { higher_level_review.start_review! }

        context "when it is set" do
          context "when it is a valid option" do
            let(:informal_conference) { true }
            it { is_expected.to be true }
          end
        end

        context "when it is nil" do
          it "adds error to informal_conference" do
            is_expected.to be nil
            expect(higher_level_review.errors[:informal_conference]).to include("blank")
          end
        end
      end
    end

    context "same_office" do
      context "when saving review" do
        before { higher_level_review.start_review! }

        context "when it is set" do
          context "when it is a valid option" do
            let(:same_office) { false }
            it { is_expected.to be false }
          end
        end

        context "when it is nil" do
          it "adds error to same_office" do
            is_expected.to be nil
            expect(higher_level_review.errors[:same_office]).to include("blank")
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
