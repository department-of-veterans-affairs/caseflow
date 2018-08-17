describe HigherLevelReviewIntake do
  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:veteran_file_number) { "64205555" }
  let(:user) { Generators::User.build }
  let(:detail) { nil }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:completed_at) { nil }

  let(:intake) do
    HigherLevelReviewIntake.new(
      user: user,
      detail: detail,
      veteran_file_number: veteran_file_number,
      completed_at: completed_at
    )
  end

  context "#cancel!" do
    subject { intake.cancel!(reason: "system_error", other: nil) }

    let(:detail) do
      HigherLevelReview.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    let!(:claimant) do
      Claimant.create!(
        review_request: detail,
        participant_id: "1234",
        payee_code: "10"
      )
    end

    it "cancels and deletes the Higher-Level Review record created" do
      subject

      expect(intake.reload).to be_canceled
      expect { detail.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(intake).to have_attributes(
        cancel_reason: "system_error",
        cancel_other: nil
      )
      expect { claimant.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context "#review!" do
    subject { intake.review!(params) }

    let(:receipt_date) { 1.day.ago }
    let(:informal_conference) { false }
    let(:same_office) { false }
    let(:claimant) { nil }
    let(:payee) { nil }

    let(:detail) do
      HigherLevelReview.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    let(:params) do
      ActionController::Parameters.new(
        receipt_date: receipt_date,
        informal_conference: informal_conference,
        same_office: same_office,
        claimant: claimant,
        payee: payee
      )
    end

    context "Veteran is claimant" do
      it "adds veteran to claimants" do
        subject

        expect(intake.detail.claimants.count).to eq 1
        expect(intake.detail.claimants.first).to have_attributes(
          participant_id: intake.veteran.participant_id,
          payee_code: "00"
        )
      end
    end

    context "Claimant is different than Veteran" do
      let(:claimant) { "1234" }
      let(:payee) { "10" }

      it "adds other relationship to claimants" do
        subject

        expect(intake.detail.claimants.count).to eq 1
        expect(intake.detail.claimants.first).to have_attributes(
          participant_id: "1234",
          payee_code: "10"
        )
      end
    end
  end

  context "#complete!" do
    subject { intake.complete!(params) }

    before do
      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
      allow(Fakes::VBMSService).to receive(:associate_rated_issues!).and_call_original
    end

    let(:params) do
      { request_issues: [
        { profile_date: "2018-04-30", reference_id: "reference-id", decision_text: "decision text" },
        { decision_text: "non-rated issue text", issue_category: "surgery", decision_date: 4.days.ago }
      ] }
    end

    let(:detail) do
      HigherLevelReview.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    let!(:claimant) do
      Claimant.create!(
        review_request: detail,
        participant_id: "1234"
      )
    end

    it "completes the intake and creates an end product" do
      subject

      ratings_end_product_establishment = EndProductEstablishment.find_by(source: intake.reload.detail, code: "030HLRR")
      nonratings_end_product_establishment = EndProductEstablishment.find_by(
        source: intake.reload.detail,
        code: "030HLRNR"
      )

      expect(intake).to be_success
      expect(intake.detail.established_at).to eq(Time.zone.now)
      expect(ratings_end_product_establishment).to_not be_nil
      expect(ratings_end_product_establishment.established_at).to eq(Time.zone.now)
      expect(nonratings_end_product_establishment).to_not be_nil
      expect(nonratings_end_product_establishment.established_at).to eq(Time.zone.now)

      request_issues = intake.detail.request_issues
      expect(request_issues.count).to eq 2

      expect(request_issues.first).to have_attributes(
        rating_issue_reference_id: "reference-id",
        rating_issue_profile_date: Date.new(2018, 4, 30),
        description: "decision text"
      )
      expect(request_issues.second).to have_attributes(
        description: "non-rated issue text",
        issue_category: "surgery",
        decision_date: 4.days.ago.to_date
      )
      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: intake.detail.veteran_file_number,
        claim_id: ratings_end_product_establishment.reference_id,
        contention_descriptions: ["decision text"],
        special_issues: []
      )
      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: intake.detail.veteran_file_number,
        claim_id: nonratings_end_product_establishment.reference_id,
        contention_descriptions: ["non-rated issue text"],
        special_issues: []
      )
      expect(Fakes::VBMSService).to have_received(:associate_rated_issues!).with(
        claim_id: ratings_end_product_establishment.reference_id,
        rated_issue_contention_map: { "reference-id" => request_issues.first.contention_reference_id }
      )
    end

    context "when same office is requested" do
      let(:detail) do
        HigherLevelReview.create!(
          veteran_file_number: "64205555",
          receipt_date: 3.days.ago,
          same_office: true
        )
      end

      it "adds same office to special issues" do
        subject

        ratings_end_product_establishment = EndProductEstablishment.find_by(
          source: intake.reload.detail,
          code: "030HLRR"
        )
        nonratings_end_product_establishment = EndProductEstablishment.find_by(
          source: intake.detail,
          code: "030HLRNR"
        )
        expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
          veteran_file_number: intake.detail.veteran_file_number,
          claim_id: ratings_end_product_establishment.reference_id,
          contention_descriptions: ["decision text"],
          special_issues: [{ code: "SSR", narrative: "Same Station Review" }]
        )
        expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
          veteran_file_number: intake.detail.veteran_file_number,
          claim_id: nonratings_end_product_establishment.reference_id,
          contention_descriptions: ["non-rated issue text"],
          special_issues: [{ code: "SSR", narrative: "Same Station Review" }]
        )
      end
    end

    context "when no requested issues" do
      let(:params) do
        { request_issues: [] }
      end

      it "does not establish claim" do
        expect(Fakes::VBMSService).not_to receive(:establish_claim!)
        expect(Fakes::VBMSService).not_to receive(:create_contentions!)

        expect(subject).to be_truthy
      end
    end

    context "when EPs with conflicting modifiers exist" do
      let!(:existing_eps) do
        %w[040 030 031 033].map do |modifier|
          Generators::EndProduct.build(
            veteran_file_number: "64205555",
            bgs_attrs: { end_product_type_code: modifier }
          )
        end
      end

      it "creates end products with incrementing end product modifiers" do
        subject

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: detail.receipt_date.to_date,
            end_product_modifier: "032",
            end_product_label: "Higher-Level Review Rating",
            end_product_code: "030HLRR",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false,
            claimant_participant_id: claimant.participant_id
          },
          veteran_hash: intake.veteran.to_vbms_hash
        )
      end
    end

    context "if end product creation fails" do
      let(:unknown_error) do
        Caseflow::Error::EstablishClaimFailedInVBMS.new("error")
      end

      it "clears pending status" do
        allow_any_instance_of(HigherLevelReview).to receive(
          :create_end_products_and_contentions!
        ).and_raise(unknown_error)

        expect { subject }.to raise_exception
        expect(intake.completion_status).to be_nil
      end
    end
  end
end
