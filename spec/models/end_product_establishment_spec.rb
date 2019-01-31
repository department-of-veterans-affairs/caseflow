describe EndProductEstablishment do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))

    if source.is_a?(HigherLevelReview)
      allow(source).to receive(:valid_modifiers).and_return(%w[030 031 032])
      allow(source).to receive(:invalid_modifiers).and_return(invalid_modifiers)
      allow(source).to receive(:benefit_type).and_return("compensation")
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
  let(:same_office) { false }
  let(:source) { HigherLevelReview.new(veteran_file_number: veteran_file_number, same_office: same_office) }
  let(:invalid_modifiers) { nil }
  let(:synced_status) { nil }
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
      established_at: 30.days.ago,
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
          veteran_file_number: veteran_file_number,
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
            end_product_code: "030HLRR",
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
              end_product_code: "030HLRR",
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
            veteran_file_number: veteran_file_number,
            bgs_attrs: { end_product_type_code: modifier }
          )
        end
      end

      it "returns NoAvailableModifiers error" do
        expect { subject }.to raise_error(EndProductEstablishment::NoAvailableModifiers)
      end
    end

    context "when existing EP has status CLR or CAN" do
      before do
        %w[030 031 032].each do |modifier|
          Generators::EndProduct.build(
            veteran_file_number: veteran_file_number,
            bgs_attrs: { end_product_type_code: modifier, status_type_code: %w[CLR CAN].sample }
          )
        end
      end

      it "considers those EP modifiers as open" do
        subject
        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          hash_including(veteran_hash: veteran.reload.to_vbms_hash)
        )
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
            end_product_code: "030HLRR",
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
    let(:vacols_id) { nil }
    let(:vacols_sequence_id) { nil }

    let!(:request_issues) do
      [
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          review_request: source,
          contested_rating_issue_reference_id: "reference-id",
          contested_rating_issue_profile_date: Date.new(2018, 4, 30),
          contested_issue_description: "this is a big decision"
        ),
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          review_request: source,
          contested_rating_issue_reference_id: "reference-id",
          contested_rating_issue_profile_date: Date.new(2018, 4, 30),
          vacols_id: vacols_id,
          vacols_sequence_id: vacols_sequence_id,
          contested_issue_description: "more decisionz"
        ),
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          review_request: source,
          contested_rating_issue_reference_id: "reference-id",
          contested_rating_issue_profile_date: Date.new(2018, 4, 30),
          contested_issue_description: "description too long for bgs" * 20
        ),
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          is_unidentified: true,
          unidentified_issue_text: "identity unknown",
          review_request: source,
          contested_rating_issue_reference_id: "reference-id",
          contested_rating_issue_profile_date: Date.new(2018, 4, 30)
        )
      ]
    end

    let(:contentions) do
      request_issues.map do |issue|
        contention = { description: issue.contention_text }
        issue.special_issues && contention[:special_issues] = issue.special_issues
        contention
      end.reverse
    end

    it "creates contentions and saves them to objects" do
      subject

      expect(contentions.second[:description].length).to eq(255)
      expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
        veteran_file_number: veteran_file_number,
        claim_id: end_product_establishment.reference_id,
        contentions: array_including(contentions),
        user: current_user
      )

      expect(end_product_establishment.contentions.count).to eq(4)
      expect(end_product_establishment.contentions.map(&:id)).to contain_exactly(
        *request_issues.map(&:reload).map(&:contention_reference_id).map(&:to_s)
      )
    end

    context "when issues have special issues" do
      let(:same_office) { true }
      let(:vacols_id) { 1 }
      let(:vacols_sequence_id) { 1 }

      it "sets special issues when creating the contentions" do
        subject

        expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
          veteran_file_number: veteran_file_number,
          claim_id: end_product_establishment.reference_id,
          contentions: array_including(
            { description: "this is a big decision",
              special_issues: [{ code: "SSR", narrative: "Same Station Review" }] },
            description: "more decisionz",
            special_issues: array_including(
              { code: "SSR", narrative: "Same Station Review" },
              code: "ASSOI", narrative: Constants.VACOLS_DISPOSITIONS_BY_ID.O
            )
          ),
          user: current_user
        )
      end
    end
  end

  context "#associate_rating_request_issues!" do
    before do
      allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
    end

    let(:reference_id) { "stevenasmith" }
    let(:contention_ref_id) { 1234 }
    let!(:contention) do
      Generators::Contention.build(id: contention_ref_id, claim_id: reference_id, text: "Left knee")
    end

    subject { end_product_establishment.associate_rating_request_issues! }

    context "request issue is ineligible" do
      let!(:request_issues) do
        [
          create(
            :request_issue,
            :rating,
            end_product_establishment: end_product_establishment,
            review_request: source,
            ineligible_reason: :duplicate_of_rating_issue_in_active_review
          )
        ]
      end

      it "skips ineligible rating request issues" do
        subject
        expect(Fakes::VBMSService).to_not have_received(:associate_rating_request_issues!)
      end
    end

    context "request issue is eligible" do
      let!(:request_issues) do
        [
          create(
            :request_issue,
            :rating,
            end_product_establishment: end_product_establishment,
            review_request: source,
            contention_reference_id: contention_ref_id
          )
        ]
      end

      it "sends mapping of rating request issues to contentions" do
        subject
        expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).once.with(
          claim_id: reference_id,
          rating_issue_contention_map: { request_issues[0].contested_rating_issue_reference_id => contention_ref_id }
        )
      end
    end
  end

  context "#generate_claimant_letter!" do
    subject { end_product_establishment.generate_claimant_letter! }

    context "when claimant letter has already been generated" do
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
        contested_rating_issue_reference_id: "reference-id",
        contested_rating_issue_profile_date: Date.new(2018, 4, 30),
        contested_issue_description: "this is a big decision",
        benefit_type: "compensation",
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

      context "when VBMS/BGS has a transient internal error" do
        before do
          # from https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3116/
          # rubocop:disable Metrics/LineLength
          sample_transient_error_body = '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"><env:Header/><env:Body><env:Fault><faultcode xmlns:ns1="http://www.w3.org/2003/05/soap-envelope">ns1:Server</faultcode><faultstring>gov.va.vba.vbms.ws.VbmsWSException: WssVerification Exception - Security Verification Exception GUID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx</faultstring><detail><cdm:faultDetailBean xmlns:cdm="http://vbms.vba.va.gov/cdm" cdm:message="gov.va.vba.vbms.ws.VbmsWSException: WssVerification Exception - Security Verification Exception GUID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" cdm:exceptionClassName="gov.va.vba.vbms.ws.VbmsWSException" cdm:uid="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" cdm:serverException="true"/></detail></env:Fault></env:Body></env:Envelope>'
          # rubocop:enable Metrics/LineLength

          error = VBMS::HTTPError.new(500, sample_transient_error_body)
          allow_any_instance_of(BGSService).to receive(:get_end_products).and_raise(error)
        end

        it "re-raises a transient ignorable error" do
          expect { subject }.to raise_error(EndProductEstablishment::TransientBGSSyncError)
        end
      end

      context "when VBMS/BGS has a transient network error" do
        before do
          # from https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/2888/
          # rubocop:disable Metrics/LineLength
          error = Errno::ETIMEDOUT.new('Connection timed out - Connection timed out - connect(2) for "bepprod.vba.va.gov" port 443 (bepprod.vba.va.gov:443)')
          # rubocop:enable Metrics/LineLength

          allow_any_instance_of(BGSService).to receive(:get_end_products).and_raise(error)
        end

        it "re-raises a transient ignorable error" do
          expect { subject }.to raise_error(EndProductEstablishment::TransientBGSSyncError)
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

  context "#associated_rating" do
    subject { end_product_establishment.associated_rating }
    let(:associated_claims) { [] }

    let(:promulgation_date) { end_product_establishment.established_at + 1.day }

    let!(:rating) do
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: promulgation_date,
        associated_claims: associated_claims
      )
    end

    context "when ep is one of many associated to the rating" do
      let(:associated_claims) do
        [
          { clm_id: "09123", bnft_clm_tc: end_product_establishment.code },
          { clm_id: end_product_establishment.reference_id, bnft_clm_tc: end_product_establishment.code }
        ]
      end

      it {
        is_expected.to have_attributes(
          participant_id: rating.participant_id,
          promulgation_date: rating.promulgation_date
        )
      }
    end

    context "when associated rating only has 1 ep" do
      let(:associated_claims) do
        [
          { clm_id: end_product_establishment.reference_id, bnft_clm_tc: end_product_establishment.code }
        ]
      end

      it {
        is_expected.to have_attributes(
          participant_id: rating.participant_id,
          promulgation_date: rating.promulgation_date
        )
      }

      context "when rating is before established_at date" do
        let!(:another_rating) do
          Generators::Rating.build(
            participant_id: veteran.participant_id,
            promulgation_date: end_product_establishment.established_at + 1.day,
            associated_claims: []
          )
        end
        let(:promulgation_date) { end_product_establishment.established_at - 1.day }

        it { is_expected.to eq(nil) }
      end
    end
  end

  context "#sync_decision_issues!" do
    subject { end_product_establishment.sync_decision_issues! }

    include ActiveJob::TestHelper

    after do
      clear_enqueued_jobs
    end

    context "when the end product establishment has request issues" do
      let!(:request_issues) do
        [
          create(
            :request_issue,
            end_product_establishment: end_product_establishment,
            review_request: source,
            decision_sync_submitted_at: nil
          ),
          create(
            :request_issue,
            end_product_establishment: end_product_establishment,
            review_request: source,
            decision_sync_submitted_at: nil
          )
        ]
      end

      it "submits each request issue and starts decision sync job" do
        subject

        expect(request_issues.first.reload.decision_sync_submitted_at).to_not be_nil
        expect(request_issues.second.reload.decision_sync_submitted_at).to_not be_nil

        expect(DecisionIssueSyncJob).to have_been_enqueued.with(request_issues.first)
        expect(DecisionIssueSyncJob).to have_been_enqueued.with(request_issues.second)
      end
    end

    context "when the end product establishment has effectuations" do
      let(:source) { create(:decision_document) }
      let!(:granted_decision_issue) { create(:decision_issue, disposition: "allowed", decision_review: source.appeal) }

      let!(:board_grant_effectuation) do
        BoardGrantEffectuation.create(
          granted_decision_issue: granted_decision_issue,
          end_product_establishment: end_product_establishment
        )
      end

      it "submits each effectuation and starts decision sync job" do
        subject

        expect(board_grant_effectuation.reload.decision_sync_submitted_at).to_not be_nil
        expect(DecisionIssueSyncJob).to have_been_enqueued.with(board_grant_effectuation)
      end
    end
  end

  context "#on_decision_issue_sync_processed" do
    subject { end_product_establishment.on_decision_issue_sync_processed }
    let(:processed_at) { Time.zone.now }
    let!(:request_issues) do
      [
        create(:request_issue,
               review_request: source,
               decision_sync_processed_at: Time.zone.now),
        create(:request_issue,
               review_request: source,
               decision_sync_processed_at: processed_at)
      ]
    end

    context "when decision issues are all synced" do
      context "when source is a higher level review" do
        let!(:claimant) do
          Claimant.create!(
            review_request: source,
            participant_id: veteran.participant_id,
            payee_code: "10"
          )
        end

        let!(:decision_issue) do
          create(:decision_issue,
                 decision_review: source,
                 disposition: HigherLevelReview::DTA_ERROR_PMR,
                 rating_issue_reference_id: "rating1",
                 end_product_last_action_date: 5.days.ago.to_date)
        end

        it "creates a supplemental claim if dta errors exist" do
          subject

          expect(SupplementalClaim.find_by(
                   decision_review_remanded: source,
                   veteran_file_number: source.veteran_file_number
                 )).to_not be_nil
        end
      end

      context "when source is a supplemental claim" do
        let(:source) { SupplementalClaim.new(veteran_file_number: veteran_file_number) }

        it "does nothing" do
          subject
          expect(SupplementalClaim.find_by(decision_review_remanded: source)).to be_nil
        end
      end
    end

    context "when decision issues are not all synced" do
      let(:processed_at) { nil }

      it "does nothing" do
        subject
        expect(SupplementalClaim.find_by(decision_review_remanded: source)).to be_nil
      end
    end
  end

  context "#status" do
    subject { epe.status }

    context "if there is an end product" do
      let(:epe) do
        create(
          :end_product_establishment,
          source: source,
          veteran_file_number: veteran_file_number,
          modifier: modifier,
          synced_status: synced_status,
          established_at: 30.days.ago,
          committed_at: 30.days.ago
        )
      end

      let(:modifier) { nil }

      context "and there is a modifier, show the modifier" do
        let(:modifier) { "037" }

        context "when there is a status" do
          let(:synced_status) { "CLR" }

          let!(:pending_request_issue) do
            create(
              :request_issue,
              review_request: epe.source,
              end_product_establishment: epe
            )
          end

          it { is_expected.to eq(ep_code: "EP 037", ep_status: "Cleared") }

          context "when there are pending request issues to sync" do
            let!(:pending_request_issue) do
              create(
                :request_issue,
                review_request: epe.source,
                end_product_establishment: epe,
                decision_sync_submitted_at: Time.zone.now
              )
            end

            it { is_expected.to eq(ep_code: "EP 037", ep_status: "Cleared, Syncing decisions...") }

            context "when there are pending request issues to sync with errors" do
              let!(:errored_request_issue) do
                create(
                  :request_issue,
                  review_request: epe.source,
                  end_product_establishment: epe,
                  decision_sync_submitted_at: Time.zone.now,
                  decision_sync_error: "oh no"
                )
              end

              it do
                is_expected.to eq(
                  ep_code: "EP 037",
                  ep_status: "Cleared, Decisions sync failed. Support notified."
                )
              end
            end
          end
        end
      end

      context "if there is no modifier, shows unknown" do
        it { is_expected.to eq(ep_code: "EP Unknown", ep_status: "") }
      end
    end

    context "if there is not an end product" do
      let(:epe) do
        create(
          :end_product_establishment,
          source: source,
          veteran_file_number: veteran_file_number,
          established_at: nil
        )
      end

      context "if there was an error establishing the claim review" do
        before { source.establishment_error = "big error" }
        let(:expected_result) do
          { ep_code: "",
            ep_status: COPY::OTHER_REVIEWS_TABLE_ESTABLISHMENT_FAILED }
        end

        it { is_expected.to eq expected_result }
      end

      context "if it is establishing" do
        let(:expected_result) do
          { ep_code: "",
            ep_status: COPY::OTHER_REVIEWS_TABLE_ESTABLISHING }
        end

        it { is_expected.to eq expected_result }
      end
    end
  end

  context "#search_table_ui_hash" do
    it "sets a null modifier to empty string so it displays correctly" do
      expect([*end_product_establishment].map(&:search_table_ui_hash)).to include(hash_including(
                                                                                    modifier: ""
                                                                                  ))
    end
  end
end
