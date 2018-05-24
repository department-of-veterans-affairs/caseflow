describe SupplementalClaim do
  before do
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:receipt_date) { nil }
  let(:end_product_reference_id) { nil }
  let(:established_at) { nil }
  let(:end_product_status) { nil }

  let(:supplemental_claim) do
    SupplementalClaim.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      end_product_reference_id: end_product_reference_id,
      established_at: established_at,
      end_product_status: end_product_status
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

  context "#create_issues!" do
    before { supplemental_claim.save! }
    subject { supplemental_claim.create_issues!(request_issues_data: request_issues_data) }

    let!(:request_issues_data) do
      [
        { reference_id: "abc", profile_date: "2018-04-04", decision_text: "hello" },
        { reference_id: "def", profile_date: "2018-04-08", decision_text: "goodbye" }
      ]
    end

    let!(:outdated_issue) do
      supplemental_claim.request_issues.create!(
        rating_issue_reference_id: "000",
        rating_issue_profile_date: Date.new,
        description: "i will be destroyed"
      )
    end

    it "creates issues from request_issues_data" do
      subject
      expect(supplemental_claim.request_issues.count).to eq(2)
      expect(supplemental_claim.request_issues.find_by(rating_issue_reference_id: "abc")).to have_attributes(
        rating_issue_profile_date: Date.new(2018, 4, 4),
        description: "hello"
      )
    end
  end

  context "#create_end_product_and_contentions!" do
    subject { supplemental_claim.create_end_product_and_contentions! }
    let(:veteran) { Veteran.new(file_number: veteran_file_number) }
    let(:receipt_date) { 2.days.ago }
    let!(:request_issues_data) do
      [
        { reference_id: "abc", profile_date: "2018-04-04", decision_text: "hello" },
        { reference_id: "def", profile_date: "2018-04-08", decision_text: "goodbye" }
      ]
    end
    before do
      supplemental_claim.save!
      supplemental_claim.create_issues!(request_issues_data: request_issues_data)
    end

    # Stub the id of the end product being created
    before do
      Fakes::VBMSService.end_product_claim_id = "454545"
    end

    context "when option receipt_date is nil" do
      let(:receipt_date) { nil }

      it "raises error" do
        expect { subject }.to raise_error(EstablishesEndProduct::InvalidEndProductError)
      end
    end

    it "creates end product and saves end_product_reference_id" do
      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original

      subject

      expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
        claim_hash: {
          benefit_type_code: "1",
          payee_code: "00",
          predischarge: false,
          claim_type: "Claim",
          station_of_jurisdiction: "397",
          date: receipt_date.to_date,
          end_product_modifier: "040",
          end_product_label: "Supplemental Claim Review Rating",
          end_product_code: "040SCR",
          gulf_war_registry: false,
          suppress_acknowledgement_letter: false
        },
        veteran_hash: veteran.to_vbms_hash
      )

      expect(supplemental_claim.reload.end_product_reference_id).to eq("454545")
    end

    context "when VBMS throws an error" do
      before do
        allow(VBMSService).to receive(:establish_claim!).and_raise(vbms_error)
      end

      let(:vbms_error) do
        VBMS::HTTPError.new("500", "<faultstring>Claim not established. " \
          "A duplicate claim for this EP code already exists in CorpDB. Please " \
          "use a different EP code modifier. GUID: 13fcd</faultstring>")
      end

      it "raises a parsed EstablishClaimFailedInVBMS error" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Caseflow::Error::EstablishClaimFailedInVBMS)
          expect(error.error_code).to eq("duplicate_ep")
        end
      end
    end
  end
end
