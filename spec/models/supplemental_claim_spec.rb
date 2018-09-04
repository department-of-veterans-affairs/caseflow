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
  let(:established_at) { nil }

  let(:supplemental_claim) do
    SupplementalClaim.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      established_at: established_at
    )
  end

  context "#valid?" do
    subject { supplemental_claim.valid? }

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

  context "#on_sync" do
    subject { supplemental_claim.on_sync(end_product_establishment) }
    let!(:end_product_establishment) do
      create(
        :end_product_establishment,
        :cleared,
        veteran_file_number: veteran_file_number,
        source: supplemental_claim,
        last_synced_at: Time.zone.now
      )
    end

    let(:request_issues_data) do
      [
        { reference_id: "abc", profile_date: "2018-04-04", decision_text: "hello" },
        { reference_id: "def", profile_date: "2018-04-08", decision_text: "goodbye" }
      ]
    end

    let(:disposition_records) do
      [
        { claim_id: end_product_establishment.reference_id,
          contention_id: "12345",
          disposition: "Granted" },
        { claim_id: end_product_establishment.reference_id,
          contention_id: "67890",
          disposition: "Denied" }
      ]
    end

    before do
      supplemental_claim.create_issues!(request_issues_data: request_issues_data)
      RequestIssue.find_by(review_request: supplemental_claim, rating_issue_reference_id: "abc").tap do |ri|
        ri.update!(contention_reference_id: "12345")
      end
      RequestIssue.find_by(review_request: supplemental_claim, rating_issue_reference_id: "def").tap do |ri|
        ri.update!(contention_reference_id: "67890")
      end
      VBMSService.disposition_records = disposition_records
    end

    it "should add dispositions to the issues" do
      subject

      expect(RequestIssue.find_by(review_request: supplemental_claim, rating_issue_reference_id: "abc").disposition)
        .to eq("Granted")
      expect(RequestIssue.find_by(review_request: supplemental_claim, rating_issue_reference_id: "def").disposition)
        .to eq("Denied")
    end
  end
end
