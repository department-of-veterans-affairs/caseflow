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

  let(:second_non_rating_request_issue) do
    RequestIssue.new(
      review_request: claim_review,
      description: "some other issue",
      issue_category: "something",
      decision_date: 3.days.ago.to_date
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

  let!(:claimant) do
    Claimant.create!(
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

    subject { claim_review.process_end_product_establishments! }

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
          contention_descriptions: ["another decision text", "decision text"],
          special_issues: [],
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
              contention_descriptions: ["another decision text"],
              special_issues: [],
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
          contention_descriptions: ["decision text"],
          special_issues: [],
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
          contention_descriptions: ["surgery - Issue text"],
          special_issues: [],
          user: user
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

    let(:veteran) do
      create(
        :veteran,
        file_number: veteran_file_number,
        bgs_veteran_record: { date_of_death: nil }
      )
    end

    let!(:end_product_establishment) do
      create(
        :end_product_establishment,
        :cleared,
        veteran_file_number: veteran.file_number,
        source: claim_review,
        last_synced_at: Time.zone.now
      )
    end

    context "syncs dispositions" do
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

      it "changes request issue dispositions" do
        subject

        expect(request_issues.first.reload.disposition).to eq("Granted")
        expect(request_issues.last.reload.disposition).to eq("Denied")
      end
    end

    context "on a higher level review" do
      let(:issues) do
        [rating_request_issue, second_rating_request_issue,
         non_rating_request_issue, second_non_rating_request_issue]
      end

      let(:rating_contention) do
        Generators::Contention.build(
          claim_id: end_product_establishment.reference_id,
          text: "decision text",
          disposition: HigherLevelReview::DTA_ERROR_PMR
        )
      end

      let(:second_rating_contention) do
        Generators::Contention.build(
          claim_id: end_product_establishment.reference_id,
          text: "another decision text",
          disposition: HigherLevelReview::DTA_ERROR_FED_RECS
        )
      end

      let(:non_rating_contention) do
        Generators::Contention.build(
          claim_id: end_product_establishment.reference_id,
          text: "Issue text",
          disposition: HigherLevelReview::DTA_ERROR_EXAM_MO
        )
      end

      let(:second_non_rating_contention) do
        Generators::Contention.build(
          claim_id: end_product_establishment.reference_id,
          text: "some other issue",
          disposition: "Granted"
        )
      end

      before do
        claim_review.save!
        claim_review.create_issues!(issues)

        allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
        allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
        allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
      end

      it "does not create a supplemental claim if there are no DTAs" do
        claim_review.on_sync(end_product_establishment)
        supplemental_claim = SupplementalClaim.find_by(
          veteran_file_number: claim_review.veteran_file_number,
          receipt_date: Time.zone.now.to_date
        )
        expect(supplemental_claim).to be_nil
      end

      context "when it gets back dispositions with DTAs" do
        def verify_followup_request_issue(supplemental_claim_id, orig_request_issue)
          follow_up_issue = RequestIssue.find_by(
            review_request_id: supplemental_claim_id,
            parent_request_issue_id: orig_request_issue.id
          )

          expect(follow_up_issue).to have_attributes(
            description: orig_request_issue.description,
            review_request_type: "SupplementalClaim"
          )

          follow_up_issue
        end

        def verify_establish_claim(end_product)
          # claim, contentions and associated issues should have been created
          expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
            claim_hash: {
              benefit_type_code: "1",
              payee_code: "00",
              predischarge: false,
              claim_type: "Claim",
              station_of_jurisdiction: "397",
              date: Time.zone.now.to_date,
              end_product_modifier: "040",
              end_product_label: end_product[:label],
              end_product_code: end_product[:code],
              gulf_war_registry: false,
              suppress_acknowledgement_letter: false,
              claimant_participant_id: veteran_participant_id
            },
            veteran_hash: veteran.to_vbms_hash,
            user: User.system_user
          )
        end

        def verify_create_contentions(reference_id, issues)
          expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
            veteran_file_number: veteran.file_number,
            claim_id: reference_id,
            contention_descriptions: issues.map(&:contention_text),
            special_issues: [],
            user: User.system_user
          )
        end

        context "for rating request issues" do
          before do
            [rating_contention, second_rating_contention].each do |contention|
              RequestIssue.find_by(description: contention.text).update!(contention_reference_id: contention.id)
            end
          end

          it "creates a supplemental claim for rating request issues" do
            claim_review.on_sync(end_product_establishment)

            # find a supplemental claim by veteran id
            supplemental_claim = SupplementalClaim.find_by(
              veteran_file_number: claim_review.veteran_file_number,
              receipt_date: Time.zone.now.to_date,
              is_dta_error: true
            )
            expect(supplemental_claim).to_not be_nil

            # find the associated end_product_establishment
            supplemental_claim_end_product_establishment = EndProductEstablishment.find_by(
              code: "040HDER",
              veteran_file_number: claim_review.veteran_file_number,
              source_type: "SupplementalClaim"
            )
            expect(supplemental_claim_end_product_establishment).to_not be_nil

            # find the new request issues by the new supplemental claim created
            follow_up_issues = []
            follow_up_issues << verify_followup_request_issue(
              supplemental_claim.id,
              rating_request_issue
            )

            follow_up_issues << verify_followup_request_issue(
              supplemental_claim.id,
              second_rating_request_issue
            )

            verify_establish_claim(
              code: "040HDER",
              label: "Supplemental Claim Rating DTA",
              reference_id: supplemental_claim_end_product_establishment.reference_id
            )

            verify_create_contentions(
              supplemental_claim_end_product_establishment.reference_id,
              [rating_request_issue, second_rating_request_issue]
            )

            # for rating request issues, verify that this is called
            expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).once.with(
              claim_id: supplemental_claim_end_product_establishment.reference_id,
              rating_issue_contention_map:
              {
                "reference-id" => follow_up_issues.first.reload.contention_reference_id,
                "reference-id2" => follow_up_issues.second.reload.contention_reference_id
              }
            )
          end
        end

        context "for nonrating issues" do
          before do
            [non_rating_contention, second_non_rating_contention].each do |contention|
              RequestIssue.find_by(description: contention.text).update!(contention_reference_id: contention.id)
            end
          end

          it "creates a supplemental claim for nonrating issues" do
            claim_review.on_sync(end_product_establishment)

            supplemental_claim = SupplementalClaim.find_by(
              veteran_file_number: claim_review.veteran_file_number,
              receipt_date: Time.zone.now.to_date
            )
            expect(supplemental_claim).to_not be_nil

            supplemental_claim_end_product_establishment = EndProductEstablishment.find_by(
              code: "040HDENR",
              veteran_file_number: claim_review.veteran_file_number
            )
            expect(supplemental_claim_end_product_establishment).to_not be_nil

            follow_up_issues = []
            follow_up_issues << verify_followup_request_issue(
              supplemental_claim.id,
              non_rating_request_issue
            )

            # make sure that that issues which come back without dta errors are not created
            not_found_issue = RequestIssue.find_by(
              review_request_id: supplemental_claim.id,
              parent_request_issue_id: second_non_rating_request_issue.id
            )

            expect(not_found_issue).to be_nil

            verify_establish_claim(
              code: "040HDENR",
              label: "Supplemental Claim Nonrating DTA",
              reference_id: supplemental_claim_end_product_establishment.reference_id
            )

            verify_create_contentions(
              supplemental_claim_end_product_establishment.reference_id,
              [non_rating_request_issue]
            )
          end
        end
      end
    end
  end
end
