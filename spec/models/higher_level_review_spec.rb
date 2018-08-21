describe HigherLevelReview do
  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number) }
  let(:receipt_date) { SupplementalClaim::AMA_BEGIN_DATE + 1 }
  let(:informal_conference) { nil }
  let(:same_office) { nil }
  let(:established_at) { nil }
  let(:end_product_status) { nil }

  let(:higher_level_review) do
    HigherLevelReview.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      informal_conference: informal_conference,
      same_office: same_office,
      established_at: established_at,
      end_product_status: end_product_status
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

          it "is valid" do
            is_expected.to be true
          end
        end

        context "when they are nil" do
          it "adds errors to informal_conference and same_office" do
            is_expected.to be false
            expect(higher_level_review.errors[:informal_conference]).to include("blank")
            expect(higher_level_review.errors[:same_office]).to include("blank")
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

  context "#create_issues!" do
    before { higher_level_review.save! }
    subject { higher_level_review.create_issues!(request_issues_data: request_issues_data) }

    let!(:request_issues_data) do
      [
        { reference_id: "abc", profile_date: "2018-04-04", decision_text: "hello" },
        { reference_id: "def", profile_date: "2018-04-08", decision_text: "goodbye" },
        { issue_category: "Unknown issue category", decision_text: "Description for Unknown" },
        { issue_category: "Apportionment", decision_text: "Description for Apportionment", decision_date: "2018-04-08" }
      ]
    end

    let!(:outdated_issue) do
      higher_level_review.request_issues.create!(
        rating_issue_reference_id: "000",
        rating_issue_profile_date: Date.new,
        description: "i will be destroyed"
      )
    end

    it "creates issues from request_issues_data" do
      subject
      expect(higher_level_review.request_issues.count).to eq(4)
      expect(higher_level_review.request_issues.find_by(rating_issue_reference_id: "abc")).to have_attributes(
        rating_issue_profile_date: Date.new(2018, 4, 4),
        description: "hello"
      )
      expect(higher_level_review.request_issues.find_by(
               description: "Description for Unknown"
      )).to have_attributes(
        issue_category: "Unknown issue category",
        decision_date: nil
      )
      expect(higher_level_review.request_issues.find_by(
               description: "Description for Apportionment"
      )).to have_attributes(
        issue_category: "Apportionment",
        decision_date: Date.new(2018, 4, 8)
      )
    end
  end

  context "#create_end_products_and_contentions!" do
    subject { higher_level_review.create_end_products_and_contentions! }
    let(:receipt_date) { 2.days.ago }
    let!(:request_issues_data) do
      [
        { reference_id: "abc", profile_date: "2018-04-04", decision_text: "hello" },
        { reference_id: "def", profile_date: "2018-04-08", decision_text: "goodbye" },
        { issue_category: "Unknown issue category", decision_text: "Description for Unknown" },
        { issue_category: "Apportionment", decision_text: "Description for Apportionment", decision_date: "2018-04-08" }
      ]
    end
    before do
      higher_level_review.save!
      higher_level_review.create_issues!(request_issues_data: request_issues_data)
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "10")
    end

    context "when option receipt_date is nil" do
      let(:receipt_date) { nil }

      it "raises error" do
        expect { subject }.to raise_error(EndProductEstablishment::InvalidEndProductError)
      end
    end

    context "when neither a ratings or nonratings end product are established" do
      let!(:request_issues_data) { [] }
      it "should not update established at" do
        allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
        subject
        expect(Fakes::VBMSService).not_to have_received(:establish_claim!)
        expect(higher_level_review.reload.established_at).to be_nil
      end
    end

    it "creates end product" do
      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original

      subject

      # ratings issues end product
      expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
        claim_hash: {
          benefit_type_code: "1",
          payee_code: "10",
          predischarge: false,
          claim_type: "Claim",
          station_of_jurisdiction: "397",
          date: receipt_date.to_date,
          end_product_modifier: "030",
          end_product_label: "Higher-Level Review Rating",
          end_product_code: "030HLRR",
          gulf_war_registry: false,
          suppress_acknowledgement_letter: false,
          claimant_participant_id: "12345"
        },
        veteran_hash: veteran.to_vbms_hash
      )
      # nonratings issues end product
      expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
        claim_hash: {
          benefit_type_code: "1",
          payee_code: "10",
          predischarge: false,
          claim_type: "Claim",
          station_of_jurisdiction: "397",
          date: receipt_date.to_date,
          end_product_modifier: "031",
          end_product_label: "Higher-Level Review Nonrating",
          end_product_code: "030HLRNR",
          gulf_war_registry: false,
          suppress_acknowledgement_letter: false,
          claimant_participant_id: "12345"
        },
        veteran_hash: veteran.to_vbms_hash
      )

      expect(EndProductEstablishment.find_by(source: higher_level_review.reload, code: "030HLRR")
        .reference_id).to_not be_nil
      expect(EndProductEstablishment.find_by(source: higher_level_review.reload, code: "030HLRNR")
        .reference_id).to_not be_nil
    end

    it "creates contentions" do
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original

      subject

      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        hash_including(
          veteran_file_number: veteran_file_number,
          contention_descriptions: array_including("Description for Unknown", "goodbye", "hello"),
          special_issues: []
        )
      )
      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        hash_including(
          veteran_file_number: veteran_file_number,
          contention_descriptions: ["Description for Apportionment"],
          special_issues: []
        )
      )
      request_issues = higher_level_review.request_issues
      expect(request_issues.first.contention_reference_id).to_not be_nil
      expect(request_issues.second.contention_reference_id).to_not be_nil
      expect(request_issues.third.contention_reference_id).to_not be_nil
      expect(request_issues.last.contention_reference_id).to_not be_nil
    end

    it "maps rated issues to contentions" do
      allow(Fakes::VBMSService).to receive(:associate_rated_issues!).and_call_original

      subject

      request_issues = higher_level_review.request_issues
      expect(Fakes::VBMSService).to have_received(:associate_rated_issues!).with(
        hash_including(
          rated_issue_contention_map: {
            "def" => request_issues.find_by(rating_issue_reference_id: "def").contention_reference_id,
            "abc" => request_issues.find_by(rating_issue_reference_id: "abc").contention_reference_id
          }
        )
      )
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
