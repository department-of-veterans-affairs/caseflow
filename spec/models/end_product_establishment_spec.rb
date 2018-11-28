describe EndProductEstablishment do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))

    if source.is_a?(HigherLevelReview)
      allow(source).to receive(:valid_modifiers).and_return(%w[030 031 032])
      allow(source).to receive(:invalid_modifiers).and_return(invalid_modifiers)
      allow(source).to receive(:special_issues).and_return(special_issues)
    end
  end

  let(:veteran_file_number) { "12341234" }
  let(:veteran_participant_id) { "11223344" }
  let!(:veteran) do
    Generators::Veteran.create(
      file_number: veteran_file_number,
      participant_id: veteran_participant_id
    )
  end
  let(:current_user) { Generators::User.build }
  let(:code) { "030HLRR" }
  let(:payee_code) { "00" }
  let(:reference_id) { nil }
  let(:source) { HigherLevelReview.new(veteran_file_number: veteran_file_number) }
  let(:invalid_modifiers) { nil }
  let(:synced_status) { nil }
  let(:special_issues) { nil }
  let(:committed_at) { nil }
  let(:fake_claim_id) { "FAKECLAIMID" }
  let(:benefit_type_code) { "2" }
  let(:doc_reference_id) { nil }
  let(:development_item_reference_id) { nil }

  let(:end_product_establishment) do
    EndProductEstablishment.new(
      source: source,
      veteran_file_number: veteran_file_number,
      code: code,
      payee_code: payee_code,
      claim_date: 2.days.ago,
      station: "397",
      reference_id: reference_id,
      claimant_participant_id: veteran_participant_id,
      synced_status: synced_status,
      committed_at: committed_at,
      benefit_type_code: benefit_type_code,
      doc_reference_id: doc_reference_id,
      development_item_reference_id: development_item_reference_id,
      user: current_user
    )
  end

  let(:vbms_error) do
    VBMS::HTTPError.new("500", "More EPs more problems")
  end

  context "#perform!" do
    subject { end_product_establishment.perform! }

    before do
      Fakes::VBMSService.end_product_claim_ids_by_file_number ||= {}
      Fakes::VBMSService.end_product_claim_ids_by_file_number[veteran.file_number] = fake_claim_id
      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    end

    context "when end product and contentions are already established" do
      let(:reference_id) { "reference-id" }

      it "does nothing and returns" do
        subject
        expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
      end
    end

    context "when end product is not valid" do
      let(:code) { nil }

      it "raises InvalidEndProductError" do
        expect { subject }.to raise_error(EndProductEstablishment::InvalidEndProductError)
      end
    end

    context "when VBMS throws an error" do
      let(:vbms_error) { VBMS::HTTPError.new("500", "PIF is already in use") }

      before do
        allow(VBMSService).to receive(:establish_claim!).and_raise(vbms_error)
      end

      it "re-raises EstablishClaimFailedInVBMS error" do
        expect { subject }.to raise_error(Caseflow::Error::EstablishClaimFailedInVBMS)
      end
    end

    context "when eps with a valid modifiers already exist" do
      let!(:past_created_ep) do
        Generators::EndProduct.build(
          veteran_file_number: "12341234",
          bgs_attrs: { end_product_type_code: "030" }
        )
      end

      it "creates an end product with the next valid modifier" do
        subject
        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: Veteran::BENEFIT_TYPE_CODE_DEATH,
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            end_product_modifier: "031",
            end_product_code: HigherLevelReview::END_PRODUCT_RATING_CODE,
            end_product_label: "Higher-Level Review Rating",
            station_of_jurisdiction: "397",
            date: 2.days.ago.to_date,
            suppress_acknowledgement_letter: false,
            gulf_war_registry: false,
            claimant_participant_id: "11223344"
          },
          veteran_hash: veteran.reload.to_vbms_hash,
          user: current_user
        )
        expect(end_product_establishment.reload).to have_attributes(
          modifier: "031"
        )
      end

      context "when invalid modifiers is set" do
        let(:invalid_modifiers) { ["031"] }

        it "creates an ep with the next valid modifier" do
          subject
          expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
            claim_hash: {
              benefit_type_code: Veteran::BENEFIT_TYPE_CODE_DEATH,
              payee_code: "00",
              predischarge: false,
              claim_type: "Claim",
              end_product_modifier: "032",
              end_product_code: HigherLevelReview::END_PRODUCT_RATING_CODE,
              end_product_label: "Higher-Level Review Rating",
              station_of_jurisdiction: "397",
              date: 2.days.ago.to_date,
              suppress_acknowledgement_letter: false,
              gulf_war_registry: false,
              claimant_participant_id: "11223344"
            },
            veteran_hash: veteran.reload.to_vbms_hash,
            user: current_user
          )
          expect(end_product_establishment.reload).to have_attributes(
            modifier: "032"
          )
        end
      end
    end

    context "when there are no open modifiers" do
      before do
        %w[030 031 032].each do |modifier|
          Generators::EndProduct.build(
            veteran_file_number: "12341234",
            bgs_attrs: { end_product_type_code: modifier }
          )
        end
      end

      it "returns NoAvailableModifiers error" do
        expect { subject }.to raise_error(EndProductEstablishment::NoAvailableModifiers)
      end
    end

    context "when all goes well" do
      it "creates end product and sets reference_id" do
        subject

        expect(end_product_establishment.reload).to have_attributes(
          reference_id: fake_claim_id,
          veteran_file_number: veteran_file_number,
          established_at: Time.zone.now,
          committed_at: nil,
          modifier: "030"
        )

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: Veteran::BENEFIT_TYPE_CODE_DEATH,
            payee_code: "00",
            claimant_participant_id: veteran_participant_id,
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: 2.days.ago.to_date,
            end_product_modifier: "030",
            end_product_label: "Higher-Level Review Rating",
            end_product_code: HigherLevelReview::END_PRODUCT_RATING_CODE,
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false
          },
          veteran_hash: veteran.reload.to_vbms_hash,
          user: current_user
        )
      end

      context "when commit is set" do
        subject { end_product_establishment.perform!(commit: true) }

        it "also commits the end product establishment" do
          subject

          expect(end_product_establishment.reload).to have_attributes(committed_at: Time.zone.now)
        end
      end
    end
  end

  context "#create_contentions!" do
    before do
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
    end

    subject { end_product_establishment.create_contentions! }

    let(:reference_id) { "stevenasmith" }

    let!(:request_issues) do
      [
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          review_request: source,
          rating_issue_reference_id: "reference-id",
          rating_issue_profile_date: Date.new(2018, 4, 30),
          description: "this is a big decision"
        ),
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          review_request: source,
          rating_issue_reference_id: "reference-id",
          rating_issue_profile_date: Date.new(2018, 4, 30),
          description: "more decisionz"
        ),
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          review_request: source,
          rating_issue_reference_id: "reference-id",
          rating_issue_profile_date: Date.new(2018, 4, 30),
          description: "this is a big decision", # intentional duplicate
        ),
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          is_unidentified: true,
          description: "identity unknown",
          review_request: source,
          rating_issue_reference_id: "reference-id",
          rating_issue_profile_date: Date.new(2018, 4, 30)
        )
      ]
    end

    let(:contention_descriptions) { request_issues.map(&:contention_text).reverse }

    it "creates contentions and saves them to objects" do
      subject

      expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
        veteran_file_number: veteran_file_number,
        claim_id: end_product_establishment.reference_id,
        contention_descriptions: array_including(contention_descriptions),
        special_issues: [],
        user: current_user
      )

      expect(end_product_establishment.contentions.count).to eq(4)
      expect(end_product_establishment.contentions.map(&:id)).to contain_exactly(
        *request_issues.map(&:reload).map(&:contention_reference_id).map(&:to_s)
      )
    end

    context "when source has special issues" do
      let(:special_issues) { "SPECIALISSUES!" }

      it "sets special issues when creating the contentions" do
        subject

        expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
          veteran_file_number: veteran_file_number,
          claim_id: end_product_establishment.reference_id,
          contention_descriptions: array_including(contention_descriptions),
          special_issues: "SPECIALISSUES!",
          user: current_user
        )
      end
    end
  end

  context "#generate_claimant_letter!" do
    subject { end_product_establishment.generate_claimant_letter! }

    context "when claimant letter has already been generated" do
      before do
        # Cleaning Fakes:BGSService because it seems to persist between tests
        Fakes::BGSService.manage_claimant_letter_v2_requests = nil
      end

      let(:doc_reference_id) { "doc_exists" }

      it "does not create a new claimant letter" do
        subject
        expect(Fakes::BGSService.manage_claimant_letter_v2_requests).to be_nil
        expect(end_product_establishment.doc_reference_id).to eq("doc_exists")
      end
    end

    context "when there is no claimant letter" do
      let(:doc_reference_id) { nil }
      let(:benefit_type_code) { "1" }

      it "generates a new claimant letter" do
        subject

        letter_request = Fakes::BGSService.manage_claimant_letter_v2_requests
        expect(letter_request[end_product_establishment.reference_id]).to eq(
          program_type_cd: "CPL", claimant_participant_id: veteran_participant_id
        )
        expect(end_product_establishment.doc_reference_id).to eq("doc_reference_id_result")
      end
    end
  end

  context "#generate_tracked_item!" do
    subject { end_product_establishment.generate_tracked_item! }

    context "when tracked item has already been generated" do
      before do
        # Cleaning Fakes:BGSService because it seems to persist between tests
        Fakes::BGSService.generate_tracked_items_requests = nil
      end

      let(:development_item_reference_id) { "tracked_item_exists" }

      it "does not create a new tracked item" do
        subject
        expect(Fakes::BGSService.generate_tracked_items_requests).to be_nil
        expect(end_product_establishment.development_item_reference_id).to eq("tracked_item_exists")
      end
    end

    context "when there is no tracked item" do
      let(:development_item_reference_id) { nil }

      it "creates a new tracked item" do
        subject
        tracked_item_request = Fakes::BGSService.generate_tracked_items_requests
        expect(tracked_item_request[end_product_establishment.reference_id]).to be(true)
      end
    end
  end

  context "#commit!" do
    subject { end_product_establishment.commit! }

    it "commits the end product establishment" do
      subject
      expect(end_product_establishment.committed_at).to eq(Time.zone.now)
    end

    context "when end_product_establishment is already committed" do
      let(:committed_at) { 2.days.ago }

      it "does not recommit the end product establishment" do
        subject
        expect(end_product_establishment.committed_at).to eq(2.days.ago)
      end
    end
  end

  context "#remove_contention!" do
    before do
      allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original
    end

    let(:reference_id) { "stevenasmith" }
    let(:contention_ref_id) { 1234 }

    let(:for_object) do
      RequestIssue.new(
        review_request: source,
        rating_issue_reference_id: "reference-id",
        rating_issue_profile_date: Date.new(2018, 4, 30),
        description: "this is a big decision",
        contention_reference_id: contention_ref_id
      )
    end

    let!(:contention) do
      Generators::Contention.build(id: contention_ref_id, claim_id: reference_id, text: "Left knee")
    end

    subject { end_product_establishment.remove_contention!(for_object) }

    it "calls VBMS with the appropriate arguments to remove the contention" do
      subject

      expect(Fakes::VBMSService).to have_received(:remove_contention!).once.with(contention)
      expect(for_object.removed_at).to eq(Time.zone.now)
    end

    context "when VBMS throws an error" do
      before do
        allow(Fakes::VBMSService).to receive(:remove_contention!).and_raise(vbms_error)
      end

      it "does not remove contentions" do
        expect { subject }.to raise_error(vbms_error)
        expect(for_object.removed_at).to be_nil
      end
    end
  end

  context "#result" do
    subject { end_product_establishment.result }

    let!(:other_ep) { Generators::EndProduct.build(veteran_file_number: veteran_file_number) }
    let!(:matching_ep) { Generators::EndProduct.build(veteran_file_number: veteran_file_number) }

    context "when matching end product has not yet been established" do
      context "when end_product.claim_id is nil" do
        it { is_expected.to be_nil }
      end

      context "when end_product_establishment.reference_id is set" do
        let(:reference_id) { "not matching" }

        it "raises EstablishedEndProductNotFound error" do
          expect { subject }.to raise_error(EndProductEstablishment::EstablishedEndProductNotFound)
        end
      end
    end

    context "when a matching end product has been established" do
      let(:reference_id) { matching_ep.claim_id }

      it { is_expected.to have_attributes(claim_id: matching_ep.claim_id) }
    end
  end

  context "#status_active?" do
    let(:end_product) do
      Generators::EndProduct.build(
        veteran_file_number: veteran_file_number,
        bgs_attrs: { status_type_code: ep_status_code }
      )
    end

    let(:ep_status_code) { "PEND" }

    let(:reference_id) { end_product.claim_id }

    context "when sync is set" do
      subject { end_product_establishment.status_active?(sync: true) }

      context "when the EP is cleared" do
        let(:synced_status) { "PEND" }
        let(:ep_status_code) { "CLR" }

        it { is_expected.to eq(false) }
      end

      context "when the EP is pending" do
        let(:ep_status_code) { "PEND" }

        it { is_expected.to eq(true) }
      end
    end

    context "when sync is not set" do
      subject { end_product_establishment.status_active? }

      context "when the EP is cleared" do
        let(:synced_status) { "CLR" }

        it { is_expected.to eq(false) }
      end

      context "when synced status is pending" do
        let(:synced_status) { "PEND" }
        let(:ep_status_code) { "CLR" }

        it { is_expected.to eq(true) }
      end
    end
  end

  context "#sync!" do
    subject { end_product_establishment.sync! }

    context "returns true if inactive" do
      let(:synced_status) { EndProduct::INACTIVE_STATUSES.first }

      it { is_expected.to eq(true) }
    end

    context "when matching end product has not yet been established" do
      it "raises EstablishedEndProductNotFound error" do
        expect { subject }.to raise_error(EndProductEstablishment::EstablishedEndProductNotFound)
      end
    end

    context "when a matching end product has been established" do
      let(:reference_id) { matching_ep.claim_id }
      let!(:matching_ep) do
        Generators::EndProduct.build(
          veteran_file_number: veteran_file_number,
          bgs_attrs: { status_type_code: "CAN" }
        )
      end

      context "when BGS throws an error" do
        before do
          allow_any_instance_of(BGSService).to receive(:get_end_products).and_raise(BGS::ShareError.new("E"))
        end

        it "re-raises  error" do
          expect { subject }.to raise_error(EndProductEstablishment::BGSSyncError)
        end
      end

      context "when source exists" do
        context "when source implements on_sync" do
          let(:source) { create(:ramp_election) }

          it "syncs the source as well" do
            expect(source).to receive(:on_sync).with(end_product_establishment)
            subject
          end
        end

        context "when source does not implement on_sync" do
          it "does not fail" do
            subject
          end
        end
      end

      it "updates last_synced_at and synced_status" do
        subject
        expect(end_product_establishment.reload.last_synced_at).to eq(Time.zone.now)
        expect(end_product_establishment.reload.synced_status).to eq("CAN")
      end
    end
  end

  context "#status_canceled?" do
    subject { end_product_establishment.status_canceled? }

    context "returns true if canceled" do
      let(:synced_status) { "CAN" }

      it { is_expected.to eq(true) }
    end

    context "returns false if any other status" do
      let(:synced_status) { "NOTCANCELED" }

      it { is_expected.to eq(false) }
    end
  end

  context "#sync_decision_issues!" do
    let(:rating) do
      Generators::Rating.build(
        issues: issues
      )
    end

    let(:contention_ref_id) { "123456" }
    let(:contention_ref_id_2) { "234567" }
    let(:reference_id) { "Issue1" }

    let(:issues) do
      [
        {
          reference_id: reference_id,
          decision_text: "Decision1",
          contention_reference_id: contention_ref_id,
          profile_date: Time.zone.today
        },
        { reference_id: "Issue2", decision_text: "Decision2" }
      ]
    end

    let(:higher_level_review) { create(:higher_level_review) }
    let(:end_product_establishment) { create(:end_product_establishment, :cleared, source: higher_level_review) }

    subject { end_product_establishment.sync_decision_issues! }

    before do
      allow(end_product_establishment).to receive(:potential_decision_ratings).and_return([rating])
    end

    context "for rating request issues with ratings" do
      let!(:request_issues) do
        # ep has 1 rating request issue which has a matching rating issue
        [
          create(
            :request_issue,
            review_request: higher_level_review,
            end_product_establishment: end_product_establishment,
            contention_reference_id: contention_ref_id
          )
        ]
      end

      it "connects rating issues with request issues based on contention_reference_id" do
        expect(request_issues.first.decision_issues.count).to eq(0)

        subject

        expect(request_issues.first.decision_issues.count).to eq(1)
        expect(request_issues.first.decision_issues.first.rating_issue_reference_id).to eq(reference_id)
      end

      context "EPE has cleared but rating has not yet been posted" do
        before do
          allow(end_product_establishment).to receive(:potential_decision_ratings).and_return([])
        end

        it "marks the RequestIssue for later sync via DecisionRatingIssueSyncJob" do
          subject

          request_issue = end_product_establishment.request_issues.first
          expect(request_issue.submitted?).to eq(true)
          expect(request_issue.processed?).to eq(false)
        end
      end
    end

    context "for rating request issues with some ratings" do
      before do
        allow(Fakes::VBMSService).to receive(:get_dispositions!).
          with(claim_id: end_product_establishment.reference_id).and_return(dispositions)
      end

      let(:disposition_text) {"allowed"}
      let(:dispositions) do
        [
          claim_id: end_product_establishment.reference_id,
          contention_id: contention_ref_id_2,
          disposition: disposition_text
        ]
      end
      let!(:request_issues) do
        # ep has 2 rating request issues
        # first one matches with a rating issue
        # second one does not have a matching rating issue
        [
          create(
            :request_issue,
            review_request: higher_level_review,
            end_product_establishment: end_product_establishment,
            contention_reference_id: contention_ref_id
          ),
          create(
            :request_issue,
            review_request: higher_level_review,
            end_product_establishment: end_product_establishment,
            contention_reference_id: contention_ref_id_2
          )
        ]
      end

      it "creates decision issues by matching rating issues or contentions for non-matching rating request issues" do
        expect(request_issues.first.decision_issues.count).to eq(0)
        expect(request_issues.second.decision_issues.count).to eq(0)

        subject
        # first rating request issue is matched by rating
        expect(request_issues.first.decision_issues.count).to eq(1)
        expect(request_issues.second.decision_issues.count).to eq(1)
        expect(request_issues.first.decision_issues.first.rating_issue_reference_id).to eq(reference_id)

        # second rating request isssue is matched by disposition
        second_decision_issue = request_issues.second.decision_issues.first
        expect(second_decision_issue.rating_issue_reference_id).to eq(nil)
        expect(second_decision_issue.source_request_issue_id).to eq(request_issues[1].id)
        expect(second_decision_issue.disposition).to eq(disposition_text)
      end
    end

    context "for rating request issues without any ratings" do
      let!(:request_issues) do
        # ep has 1 rating request issue which does not have any
        # matching rating issues
        [
          create(
            :request_issue,
            review_request: higher_level_review,
            end_product_establishment: end_product_establishment,
            contention_reference_id: contention_ref_id_2
          )
        ]
      end
      let(:rating){Generators::Rating.build(issues: [])}

      it "will retry rating request issue later" do
        subject

        # get_dispositions! should not be called
        expect(Fakes::VBMSService).not_to receive(:get_dispositions!)
        # request issue should not be marked as processed
        request_issue = request_issues.first
        expect(request_issue.processed?).to eq(false)

        # no decision issue is made
        expect(DecisionIssue.count).to eq(0)
      end
    end

    context "for nonrating request issues" do
      before do
        allow(Fakes::VBMSService).to receive(:get_dispositions!).
          with(claim_id: end_product_establishment.reference_id).and_return(dispositions)
      end

      let(:end_product_establishment) do
        create(:end_product_establishment,
          :cleared,
          source: higher_level_review,
          code: HigherLevelReview::END_PRODUCT_NONRATING_CODE
          )
      end

      let(:disposition_text) {"allowed"}
      let(:dispositions) do
        [
          claim_id: end_product_establishment.reference_id,
          contention_id: contention_ref_id_2,
          disposition: disposition_text
        ]
      end

      let!(:request_issues) do
        # ep has 1 non rating request issue
        [
          create(
            :request_issue,
            review_request: higher_level_review,
            end_product_establishment: end_product_establishment,
            contention_reference_id: contention_ref_id_2,
            issue_category: "Apportionment",
            decision_date: "2018-08-01"
          )
        ]
      end

      it "connects nonrating request issues based on contention disposition" do
        expect(request_issues.first.decision_issues.count).to eq(0)
        subject

        expect(request_issues.first.decision_issues.count).to eq(1)
        first_decision_issue = request_issues.first.decision_issues.first
        expect(first_decision_issue.rating_issue_reference_id).to eq(nil)
        expect(first_decision_issue.source_request_issue_id).to eq(request_issues.first.id)
        expect(first_decision_issue.disposition).to eq(disposition_text)
      end
    end
  end
end
