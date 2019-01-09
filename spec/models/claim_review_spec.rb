describe ClaimReview do
  before do
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  def random_ref_id
    SecureRandom.random_number(1_000_000)
  end

  let(:contention_ref_id) { random_ref_id }
  let(:veteran_file_number) { "4205555" }
  let(:veteran_participant_id) { "123456" }
  let(:veteran_date_of_death) { nil }
  let!(:veteran) do
    Generators::Veteran.build(
      file_number: veteran_file_number,
      first_name: "James",
      last_name: "Bond",
      participant_id: veteran_participant_id,
      date_of_death: veteran_date_of_death
    )
  end

  let(:receipt_date) { DecisionReview.ama_activation_date + 1 }
  let(:informal_conference) { nil }
  let(:same_office) { nil }
  let(:benefit_type) { "compensation" }

  let(:rating_request_issue) do
    build(
      :request_issue,
      review_request: claim_review,
      contested_rating_issue_reference_id: "reference-id",
      contested_rating_issue_profile_date: Date.new(2018, 4, 30),
      contested_issue_description: "decision text"
    )
  end

  let(:second_rating_request_issue) do
    build(
      :request_issue,
      review_request: claim_review,
      contested_rating_issue_reference_id: "reference-id2",
      contested_rating_issue_profile_date: Date.new(2018, 4, 30),
      contested_issue_description: "another decision text"
    )
  end

  let(:non_rating_request_issue) do
    build(
      :request_issue,
      review_request: claim_review,
      nonrating_issue_description: "Issue text",
      issue_category: "surgery",
      decision_date: 4.days.ago.to_date
    )
  end

  let(:second_non_rating_request_issue) do
    build(
      :request_issue,
      review_request: claim_review,
      nonrating_issue_description: "some other issue",
      issue_category: "something",
      decision_date: 3.days.ago.to_date
    )
  end

  let(:claim_review) do
    build(
      :higher_level_review,
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      informal_conference: informal_conference,
      same_office: same_office,
      benefit_type: benefit_type
    )
  end

  let!(:claimant) do
    create(
      :claimant,
      review_request: claim_review,
      participant_id: veteran_participant_id,
      payee_code: "00"
    )
  end

  let(:vbms_error) do
    VBMS::HTTPError.new("500", "More EPs more problems")
  end

  context "async logic scopes" do
    let!(:claim_review_requiring_processing) do
      create(:higher_level_review, receipt_date: receipt_date).tap(&:submit_for_processing!)
    end

    let!(:claim_review_processed) do
      create(:higher_level_review, receipt_date: receipt_date).tap(&:processed!)
    end

    let!(:claim_review_recently_attempted) do
      create(
        :higher_level_review,
        receipt_date: receipt_date,
        establishment_attempted_at: (ClaimReview::REQUIRES_PROCESSING_RETRY_WINDOW_HOURS - 1).hours.ago
      )
    end

    let!(:claim_review_attempts_ended) do
      create(
        :higher_level_review,
        receipt_date: receipt_date,
        establishment_submitted_at: (ClaimReview::REQUIRES_PROCESSING_WINDOW_DAYS + 5).days.ago,
        establishment_attempted_at: (ClaimReview::REQUIRES_PROCESSING_WINDOW_DAYS + 1).days.ago
      )
    end

    context ".unexpired" do
      it "matches reviews still inside the processing window" do
        expect(HigherLevelReview.unexpired).to eq([claim_review_requiring_processing])
      end
    end

    context ".processable" do
      it "matches reviews eligible for processing" do
        expect(HigherLevelReview.processable).to match_array(
          [claim_review_requiring_processing, claim_review_attempts_ended]
        )
      end
    end

    context ".attemptable" do
      it "matches reviews that could be attempted" do
        expect(HigherLevelReview.attemptable).not_to include(claim_review_recently_attempted)
      end
    end

    context ".requires_processing" do
      it "matches reviews that must still be processed" do
        expect(HigherLevelReview.requires_processing).to eq([claim_review_requiring_processing])
      end
    end

    context ".expired_without_processing" do
      it "matches reviews unfinished but outside the retry window" do
        expect(HigherLevelReview.expired_without_processing).to eq([claim_review_attempts_ended])
      end
    end
  end

  context "#timely_issue?" do
    before do
      Timecop.freeze(Time.utc(2019, 4, 24, 12, 0, 0))
    end

    subject { create(:higher_level_review, receipt_date: Time.zone.today) }

    context "decided in the last year" do
      it "considers it timely" do
        expect(subject.timely_issue?(Time.zone.today)).to eq(true)
      end
    end

    context "decided more than a year ago" do
      it "considers it untimely" do
        expect(subject.timely_issue?(Time.zone.today - 400)).to eq(false)
      end
    end
  end

  context "#serialized_ratings" do
    let(:ratings) do
      [
        Generators::Rating.build(promulgation_date: Time.zone.today - 30),
        Generators::Rating.build(promulgation_date: Time.zone.today - 400)
      ]
    end

    before do
      allow(subject.veteran).to receive(:ratings).and_return(ratings)
    end

    subject do
      create(:higher_level_review, veteran_file_number: veteran_file_number, receipt_date: Time.zone.today)
    end

    it "calculates timely flag" do
      serialized_ratings = subject.serialized_ratings

      expect(serialized_ratings.first[:issues]).to include(hash_including(timely: true), hash_including(timely: true))
      expect(serialized_ratings.last[:issues]).to include(hash_including(timely: false), hash_including(timely: false))
    end
  end

  context "#effectuated_in_caseflow?" do
    let(:claim_review) { create(:higher_level_review, benefit_type: benefit_type) }

    subject { claim_review.effectuated_in_caseflow? }

    context "when benefit_type is compensation" do
      let(:benefit_type) { "compensation" }

      it { is_expected.to be_falsey }
    end

    context "when benefit_type is pension" do
      let(:benefit_type) { "pension" }

      it { is_expected.to be_falsey }
    end

    context "when benefit_type is something else" do
      let(:benefit_type) { "foobar" }

      it { is_expected.to be_truthy }
    end
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

      context "when the benefit type is pension" do
        let(:benefit_type) { "pension" }

        it "creates issues and assigns pension end product codes to them" do
          subject

          expect(rating_request_issue.reload.end_product_establishment).to have_attributes(code: "030HLRRPMC")
          expect(non_rating_request_issue.reload.end_product_establishment).to have_attributes(code: "030HLRNRPMC")
        end
      end
    end
  end

  context "#establish!" do
    let!(:user) do
      User.create(
        station_id: 1,
        css_id: "test_user",
        full_name: "Test User"
      )
    end

    let!(:intake) do
      Intake.create(
        user_id: user.id,
        detail: claim_review,
        veteran_file_number: veteran.file_number,
        started_at: Time.zone.now,
        completed_at: Time.zone.now,
        completion_status: "success",
        type: "HigherLevelReviewIntake"
      )
    end

    before do
      claim_review.save!
      claim_review.create_issues!(issues)

      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
      allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
    end

    subject { claim_review.establish! }

    context "when there is just one end_product_establishment" do
      let(:issues) { [rating_request_issue, second_rating_request_issue] }

      it "establishes the claim and creates the contentions in VBMS" do
        subject

        expect(Fakes::VBMSService).to have_received(:establish_claim!).once.with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "499",
            date: claim_review.receipt_date.to_date,
            end_product_modifier: "030",
            end_product_label: "Higher-Level Review Rating",
            end_product_code: "030HLRR",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false,
            claimant_participant_id: veteran_participant_id
          },
          veteran_hash: veteran.to_vbms_hash,
          user: user
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
          veteran_file_number: veteran_file_number,
          claim_id: claim_review.end_product_establishments.last.reference_id,
          contentions: array_including({ description: "another decision text" }, description: "decision text"),
          user: user
        )

        expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).once.with(
          claim_id: claim_review.end_product_establishments.last.reference_id,
          rating_issue_contention_map: {
            "reference-id" => rating_request_issue.reload.contention_reference_id,
            "reference-id2" => second_rating_request_issue.reload.contention_reference_id
          }
        )

        expect(claim_review.end_product_establishments.first).to be_committed
        expect(rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
        expect(second_rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
      end

      context "when associate rating request issues fails" do
        before do
          allow(VBMSService).to receive(:associate_rating_request_issues!).and_raise(vbms_error)
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

        it "does not associate_rating_request_issues" do
          subject
          expect(Fakes::VBMSService).to_not have_received(:associate_rating_request_issues!)
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
          let(:one_day_ago) { 1.day.ago }

          before do
            rating_request_issue.update!(
              contention_reference_id: contention_ref_id,
              rating_issue_associated_at: one_day_ago
            )
          end

          it "doesn't create them in VBMS, and re-sends the new contention map" do
            subject

            expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
              veteran_file_number: veteran_file_number,
              claim_id: claim_review.end_product_establishments.last.reference_id,
              contentions: [{ description: "another decision text" }],
              user: user
            )

            expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).once.with(
              claim_id: claim_review.end_product_establishments.last.reference_id,
              rating_issue_contention_map: {
                "reference-id" => rating_request_issue.reload.contention_reference_id,
                "reference-id2" => second_rating_request_issue.reload.contention_reference_id
              }
            )

            expect(rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
            expect(second_rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
          end
        end

        context "when all the contentions have already been saved" do
          before do
            rating_request_issue.update!(
              contention_reference_id: contention_ref_id, rating_issue_associated_at: Time.zone.now
            )
            second_rating_request_issue.update!(
              contention_reference_id: random_ref_id, rating_issue_associated_at: Time.zone.now
            )
          end

          it "doesn't create them in VBMS" do
            subject

            expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
            expect(Fakes::VBMSService).to_not have_received(:create_contentions!)
            expect(Fakes::VBMSService).to_not have_received(:associate_rating_request_issues!)
          end
        end

        context "when informal conference already has a tracked item" do
          before do
            claim_review.end_product_establishments.first.update!(doc_reference_id: "DOC_REF_ID")
            claim_review.end_product_establishments.first.update!(
              development_item_reference_id: "dev_item_ref_id"
            )

            # Cleaning Fakes:BGSService because it seems to persist between tests
            Fakes::BGSService.manage_claimant_letter_v2_requests = nil
            Fakes::BGSService.generate_tracked_items_requests = nil
          end

          it "doesn't create it in BGS" do
            subject

            expect(Fakes::BGSService.manage_claimant_letter_v2_requests).to be_nil
            expect(Fakes::BGSService.generate_tracked_items_requests).to be_nil
          end
        end
      end

      context "when called multiple times" do
        it "remains idempotent despite multiple VBMS failures" do
          raise_error_on_end_product_establishment_establish_claim

          expect(Fakes::VBMSService).to receive(:establish_claim!).once
          expect { subject }.to raise_error(vbms_error)
          expect(claim_review.establishment_processed_at).to be_nil

          allow_end_product_establishment_establish_claim
          raise_error_on_create_contentions

          expect(Fakes::VBMSService).to receive(:establish_claim!).once
          expect(Fakes::VBMSService).to receive(:create_contentions!).once
          expect { subject }.to raise_error(vbms_error)
          expect(claim_review.establishment_processed_at).to be_nil
          expect(epe.reference_id).to_not be_nil
          expect(claim_contentions_for_all_issues_on_epe.count).to eq(0)

          allow_create_contentions
          raise_error_on_associate_rating_request_issues

          expect(Fakes::VBMSService).to_not receive(:establish_claim!)
          expect(Fakes::VBMSService).to receive(:create_contentions!).once
          expect(Fakes::VBMSService).to receive(:associate_rating_request_issues!).once
          expect { subject }.to raise_error(vbms_error)
          expect(claim_review.establishment_processed_at).to be_nil

          epe_contentions = claim_contentions_for_all_issues_on_epe
          expect(epe_contentions.count).to eq(2)
          expect(epe_contentions.where.not(rating_issue_associated_at: nil).count).to eq(0)

          allow_associate_rating_request_issues

          expect(Fakes::VBMSService).to_not receive(:establish_claim!)
          expect(Fakes::VBMSService).to_not receive(:create_contentions!)
          expect(Fakes::VBMSService).to receive(:associate_rating_request_issues!).once
          subject
          expect(claim_review.establishment_processed_at).to eq(Time.zone.now)

          expect(Fakes::VBMSService).to_not receive(:establish_claim!)
          expect(Fakes::VBMSService).to_not receive(:create_contentions!)
          expect(Fakes::VBMSService).to_not receive(:associate_rating_request_issues!)
          subject
        end

        def raise_error_on_end_product_establishment_establish_claim
          allow(Fakes::VBMSService).to receive(:establish_claim!).and_raise(vbms_error)
        end

        def allow_end_product_establishment_establish_claim
          allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
        end

        def raise_error_on_create_contentions
          allow(Fakes::VBMSService).to receive(:create_contentions!).and_raise(vbms_error)
        end

        def allow_create_contentions
          allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
        end

        def raise_error_on_associate_rating_request_issues
          allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_raise(vbms_error)
        end

        def allow_associate_rating_request_issues
          allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
        end

        def claim_contentions_for_all_issues_on_epe
          claim_review.request_issues.where(end_product_establishment: epe).where.not(contention_reference_id: nil)
        end

        def epe
          claim_review.end_product_establishments.first
        end
      end

      context "when informal conference is true" do
        let(:informal_conference) { true }

        it "generates claimant letter and tracked item" do
          subject
          epe = claim_review.end_product_establishments.last
          expect(epe).to have_attributes(
            doc_reference_id: "doc_reference_id_result",
            development_item_reference_id: "development_item_reference_id_result"
          )

          letter_request = Fakes::BGSService.manage_claimant_letter_v2_requests
          expect(letter_request[epe.reference_id]).to eq(
            program_type_cd: "CPL", claimant_participant_id: veteran_participant_id
          )

          tracked_item_request = Fakes::BGSService.generate_tracked_items_requests
          expect(tracked_item_request[epe.reference_id]).to be(true)
        end

        context "when veteran is deceased" do
          let(:veteran_date_of_death) { 1.year.ago }

          it "sets program_type_cd to CPD" do
            subject
            epe = claim_review.end_product_establishments.last

            letter_request = Fakes::BGSService.manage_claimant_letter_v2_requests
            expect(letter_request[epe.reference_id]).to eq(
              program_type_cd: "CPD", claimant_participant_id: veteran_participant_id
            )
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
            station_of_jurisdiction: "499",
            date: claim_review.receipt_date.to_date,
            end_product_modifier: "030",
            end_product_label: "Higher-Level Review Rating",
            end_product_code: "030HLRR",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false,
            claimant_participant_id: veteran_participant_id
          },
          veteran_hash: veteran.to_vbms_hash,
          user: user
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
          veteran_file_number: veteran_file_number,
          claim_id: claim_review.end_product_establishments.find_by(code: "030HLRR").reference_id,
          contentions: [{ description: "decision text" }],
          user: user
        )

        expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).once.with(
          claim_id: claim_review.end_product_establishments.find_by(code: "030HLRR").reference_id,
          rating_issue_contention_map: {
            "reference-id" => rating_request_issue.reload.contention_reference_id
          }
        )

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "499",
            date: claim_review.receipt_date.to_date,
            end_product_modifier: "031", # Important that the modifier increments for the second EP
            end_product_label: "Higher-Level Review Nonrating",
            end_product_code: "030HLRNR",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false,
            claimant_participant_id: veteran_participant_id
          },
          veteran_hash: veteran.to_vbms_hash,
          user: user
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
          veteran_file_number: veteran_file_number,
          claim_id: claim_review.end_product_establishments.find_by(code: "030HLRNR").reference_id,
          contentions: [{ description: "surgery - Issue text" }],
          user: user
        )

        expect(claim_review.end_product_establishments.first).to be_committed
        expect(claim_review.end_product_establishments.last).to be_committed
        expect(rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
        expect(non_rating_request_issue.rating_issue_associated_at).to be_nil
      end
    end
  end

  describe ".find_by_uuid_or_reference_id!" do
    let(:hlr) { create(:higher_level_review, :with_end_product_establishment).reload }

    it "finds by UUID" do
      expect(HigherLevelReview.find_by_uuid_or_reference_id!(hlr.uuid)).to eq(hlr)
    end

    it "finds by EPE reference_id" do
      hlr.end_product_establishments.first.update!(reference_id: "abc123")

      expect(HigherLevelReview.find_by_uuid_or_reference_id!("abc123")).to eq(hlr)
    end
  end
end
