describe ClaimReview do
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

  let(:rating_request_issue) do
    RequestIssue.new(
      review_request: claim_review,
      rating_issue_reference_id: "reference-id",
      rating_issue_profile_date: Date.new(2018, 4, 30),
      description: "decision text"
    )
  end

  let(:second_rating_request_issue) do
    RequestIssue.new(
      review_request: claim_review,
      rating_issue_reference_id: "reference-id2",
      rating_issue_profile_date: Date.new(2018, 4, 30),
      description: "another decision text"
    )
  end

  let(:non_rating_request_issue) do
    RequestIssue.new(
      review_request: claim_review,
      description: "Issue text",
      issue_category: "surgery",
      decision_date: 4.days.ago.to_date
    )
  end

  let(:claim_review) do
    HigherLevelReview.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      informal_conference: informal_conference,
      same_office: same_office
    )
  end

  let(:vbms_error) do
    VBMS::HTTPError.new("500", "More EPs more problems")
  end

  context "#create_issues!" do
    before { claim_review.save! }
    subject { claim_review.create_issues!(issues) }

    context "when there's just one issue" do
      let(:issues) { [rating_request_issue] }

      it "creates the issue and assigns a end product establishment" do
        subject

        expect(rating_request_issue.reload.end_product_establishment).to have_attributes(code: "030HLRR")
      end
    end

    context "when there's more than one issue" do
      let(:issues) { [rating_request_issue, non_rating_request_issue] }

      it "creates the issues and assigns end product establishments to them" do
        subject

        expect(rating_request_issue.reload.end_product_establishment).to have_attributes(code: "030HLRR")
        expect(non_rating_request_issue.reload.end_product_establishment).to have_attributes(code: "030HLRNR")
      end
    end
  end

  context "#process_end_product_establishments!" do
    before do
      claim_review.save!
      claim_review.create_issues!(issues)

      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
      allow(Fakes::VBMSService).to receive(:associate_rated_issues!).and_call_original
    end

    subject { claim_review.process_end_product_establishments! }

    context "when there is just one end_product_establishment" do
      let(:issues) { [rating_request_issue, second_rating_request_issue] }

      it "establishes the claim and creates the contetions in VBMS" do
        subject

        expect(Fakes::VBMSService).to have_received(:establish_claim!).once.with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: claim_review.receipt_date.to_date,
            end_product_modifier: "030",
            end_product_label: "Higher-Level Review Rating",
            end_product_code: "030HLRR",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false,
            claimant_participant_id: nil
          },
          veteran_hash: veteran.to_vbms_hash
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
          veteran_file_number: veteran_file_number,
          claim_id: claim_review.end_product_establishments.last.reference_id,
          contention_descriptions: ["another decision text", "decision text"],
          special_issues: []
        )

        expect(Fakes::VBMSService).to have_received(:associate_rated_issues!).once.with(
          claim_id: claim_review.end_product_establishments.last.reference_id,
          rated_issue_contention_map: {
            "reference-id" => rating_request_issue.reload.contention_reference_id,
            "reference-id2" => second_rating_request_issue.reload.contention_reference_id
          }
        )

        expect(claim_review.end_product_establishments.first).to be_committed
        expect(rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
        expect(second_rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
      end

      context "when associate rated issues fails" do
        before do
          allow(VBMSService).to receive(:associate_rated_issues!).and_raise(vbms_error)
        end

        it "does not commit the end product establishment" do
          expect { subject }.to raise_error(vbms_error)
          expect(claim_review.end_product_establishments.first).to_not be_committed
          expect(rating_request_issue.rating_issue_associated_at).to be_nil
          expect(second_rating_request_issue.rating_issue_associated_at).to be_nil
        end
      end

      context "when there are no rating issues" do
        let(:issues) { [non_rating_request_issue] }

        it "does not associate_rated_issues" do
          subject
          expect(Fakes::VBMSService).to_not have_received(:associate_rated_issues!)
          expect(non_rating_request_issue.rating_issue_associated_at).to be_nil
        end
      end

      context "when the end product was already established" do
        before { claim_review.end_product_establishments.first.update!(reference_id: "REF_ID") }

        it "doesn't establish it again in VBMS" do
          subject

          expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
          expect(Fakes::VBMSService).to have_received(:create_contentions!)
        end

        context "when some of the contentions have already been saved" do
          before do
            rating_request_issue.update!(contention_reference_id: "CONREFID")
          end

          it "doesn't create them in VBMS" do
            subject

            expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
              veteran_file_number: veteran_file_number,
              claim_id: claim_review.end_product_establishments.last.reference_id,
              contention_descriptions: ["another decision text"],
              special_issues: []
            )

            expect(Fakes::VBMSService).to have_received(:associate_rated_issues!).once.with(
              claim_id: claim_review.end_product_establishments.last.reference_id,
              rated_issue_contention_map: {
                "reference-id2" => second_rating_request_issue.reload.contention_reference_id
              }
            )

            expect(rating_request_issue.rating_issue_associated_at).to be_nil
            expect(second_rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
          end
        end

        context "when all the contentions have already been saved" do
          before do
            rating_request_issue.update!(contention_reference_id: "CONREFID")
            second_rating_request_issue.update!(contention_reference_id: "CONREFID")
          end

          it "doesn't create them in VBMS" do
            subject

            expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
            expect(Fakes::VBMSService).to_not have_received(:create_contentions!)
            expect(Fakes::VBMSService).to_not have_received(:associate_rated_issues!)
          end
        end
      end
    end

    context "when there are more than one end product establishments" do
      let(:issues) { [non_rating_request_issue, rating_request_issue] }

      it "establishes the claim and creates the contetions in VBMS for each one" do
        subject

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: claim_review.receipt_date.to_date,
            end_product_modifier: "030",
            end_product_label: "Higher-Level Review Rating",
            end_product_code: "030HLRR",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false,
            claimant_participant_id: nil
          },
          veteran_hash: veteran.to_vbms_hash
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
          veteran_file_number: veteran_file_number,
          claim_id: claim_review.end_product_establishments.find_by(code: "030HLRR").reference_id,
          contention_descriptions: ["decision text"],
          special_issues: []
        )

        expect(Fakes::VBMSService).to have_received(:associate_rated_issues!).once.with(
          claim_id: claim_review.end_product_establishments.find_by(code: "030HLRR").reference_id,
          rated_issue_contention_map: {
            "reference-id" => rating_request_issue.reload.contention_reference_id
          }
        )

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: claim_review.receipt_date.to_date,
            end_product_modifier: "031", # Important that the modifier increments for the second EP
            end_product_label: "Higher-Level Review Nonrating",
            end_product_code: "030HLRNR",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false,
            claimant_participant_id: nil
          },
          veteran_hash: veteran.to_vbms_hash
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
          veteran_file_number: veteran_file_number,
          claim_id: claim_review.end_product_establishments.find_by(code: "030HLRNR").reference_id,
          contention_descriptions: ["Issue text"],
          special_issues: []
        )

        expect(claim_review.end_product_establishments.first).to be_committed
        expect(claim_review.end_product_establishments.last).to be_committed
        expect(rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
        expect(non_rating_request_issue.rating_issue_associated_at).to be_nil
      end
    end
  end

  context "#on_sync" do
    subject { claim_review.on_sync(end_product_establishment) }

    let!(:end_product_establishment) do
      create(
        :end_product_establishment,
        :cleared,
        veteran_file_number: veteran_file_number,
        source: claim_review,
        last_synced_at: Time.zone.now
      )
    end

    let(:contentions) do
      [
        Generators::Contention.build(
          claim_id: end_product_establishment.reference_id,
          text: "hello",
          disposition: "Granted"
        ),
        Generators::Contention.build(
          claim_id: end_product_establishment.reference_id,
          text: "goodbye",
          disposition: "Denied"
        )
      ]
    end

    let!(:request_issues) do
      contentions.map do |contention|
        claim_review.request_issues.create!(
          review_request: claim_review,
          end_product_establishment: end_product_establishment,
          description: contention.text,
          contention_reference_id: contention.id
        )
      end
    end

    it "should add dispositions to the issues" do
      subject

      expect(request_issues.first.reload.disposition).to eq("Granted")
      expect(request_issues.last.reload.disposition).to eq("Denied")
    end
  end
end
