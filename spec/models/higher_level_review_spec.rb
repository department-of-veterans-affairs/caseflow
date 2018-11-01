describe HigherLevelReview do
  before do
    FeatureToggle.enable!(:intake_legacy_opt_in)
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:intake_legacy_opt_in)
  end

  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number) }
  let(:receipt_date) { HigherLevelReview::AMA_BEGIN_DATE + 1 }
  let(:benefit_type) { "compensation" }
  let(:informal_conference) { nil }
  let(:same_office) { nil }
  let(:legacy_opt_in_approved) { false }

  let(:higher_level_review) do
    HigherLevelReview.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      informal_conference: informal_conference,
      same_office: same_office,
      benefit_type: benefit_type,
      legacy_opt_in_approved: legacy_opt_in_approved
    )
  end

  context "#valid?" do
    subject { higher_level_review.valid? }

    context "receipt_date" do
      context "when it is nil" do
        let(:receipt_date) { nil }
        it { is_expected.to be true }
      end

      context "when it is after today" do
        let(:receipt_date) { 1.day.from_now }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(higher_level_review.errors[:receipt_date]).to include("in_future")
        end
      end

      context "when it is before AMA begin date" do
        let(:receipt_date) { SupplementalClaim::AMA_BEGIN_DATE - 1 }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(higher_level_review.errors[:receipt_date]).to include("before_ama")
        end
      end

      context "when saving receipt" do
        before { higher_level_review.start_review! }

        context "when it is nil" do
          let(:receipt_date) { nil }

          it "adds error to receipt_date" do
            is_expected.to be false
            expect(higher_level_review.errors[:receipt_date]).to include("blank")
          end
        end
      end
    end

    context "informal_conference and same_office" do
      context "when saving review" do
        before { higher_level_review.start_review! }

        context "when they are set" do
          let(:informal_conference) { true }
          let(:same_office) { false }
          let(:legacy_opt_in_approved) { false }

          it "is valid" do
            is_expected.to be true
          end
        end

        context "when they are nil" do
          let(:legacy_opt_in_approved) { nil }
          it "adds errors to informal_conference and same_office" do
            is_expected.to be false
            expect(higher_level_review.errors[:informal_conference]).to include("blank")
            expect(higher_level_review.errors[:same_office]).to include("blank")
            expect(higher_level_review.errors[:legacy_opt_in_approved]).to include("blank")
          end
        end
      end
    end
  end

  context "#claimant_participant_id" do
    subject { higher_level_review.claimant_participant_id }

    it "returns claimant's participant ID" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "00")
      higher_level_review.save!
      expect(subject).to eql("12345")
    end

    it "returns new claimant's participant ID if replaced" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "00")
      higher_level_review.create_claimants!(participant_id: "23456", payee_code: "00")
      higher_level_review.reload
      expect(subject).to eql("23456")
    end

    it "returns nil when there are no claimants" do
      expect(subject).to be_nil
    end
  end

  context "#payee_code" do
    subject { higher_level_review.payee_code }

    it "returns claimant's payee_code" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "10")
      higher_level_review.save!
      expect(subject).to eql("10")
    end

    it "returns new claimant's payee_code if replaced" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "10")
      higher_level_review.create_claimants!(participant_id: "23456", payee_code: "11")
      higher_level_review.reload
      expect(subject).to eql("11")
    end

    it "returns nil when there are no claimants" do
      expect(subject).to be_nil
    end
  end

  context "#claimant_not_veteran" do
    subject { higher_level_review.claimant_not_veteran }

    it "returns true if claimant is not veteran" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "10")
      expect(subject).to be true
    end

    it "returns false if claimant is veteran" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: veteran.participant_id, payee_code: "00")
      expect(subject).to be false
    end

    it "returns nil if there are no claimants" do
      expect(subject).to be_nil
    end
  end
end
