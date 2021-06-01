# frozen_string_literal: true

describe EndProductEstablishment, :postgres do
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
  let(:source) { create(:higher_level_review, veteran_file_number: veteran_file_number, same_office: same_office) }
  let(:invalid_modifiers) { [] }
  let(:synced_status) { nil }
  let(:committed_at) { nil }
  let(:fake_claim_id) { "FAKECLAIMID" }
  let(:benefit_type_code) { "2" }
  let(:doc_reference_id) { nil }
  let(:development_item_reference_id) { nil }
  let(:limited_poa_code) { "ABC" }
  let(:limited_poa_access) { true }
  let(:rating_profile_date) { Date.new(2018, 4, 30) }
  let(:last_synced_at) { nil }

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
      user: current_user,
      limited_poa_code: limited_poa_code,
      limited_poa_access: limited_poa_access,
      last_synced_at: last_synced_at
    )
  end
  let(:orphaned_end_product) do
    EndProduct.new(
      claim_id: "1234",
      claim_date: end_product_establishment.claim_date,
      claim_type_code: end_product_establishment.code,
      payee_code: end_product_establishment.payee_code,
      status_type_code: "PEND"
    )
  end

  let(:vbms_error) do
    VBMS::HTTPError.new("500", "More EPs more problems")
  end

  context "#last_action_date" do
    subject { end_product_establishment.last_action_date }

    let(:last_action_date) { 5.days.ago.mdY }
    let(:last_synced_at) { 4.days.ago }
    let(:reference_id) { matching_ep.claim_id }

    let!(:matching_ep) do
      Generators::EndProduct.build(
        veteran_file_number: veteran_file_number,
        bgs_attrs: {
          last_action_date: last_action_date,
          status_type_code: "CLR"
        }
      )
    end

    it { is_expected.to eq 5.days.ago.to_date }

    context "when the EP last action date is nil" do
      let(:last_action_date) { nil }

      it { is_expected.to eq last_synced_at.to_date }
    end
  end

  context "#status_type_code" do
    subject { end_product_establishment.status_type_code }

    it "returns pending" do
      expect(subject).to eq("PEND")
    end

    context "board grant effectuation" do
      let(:code) { "030BGR" }
      it "returns ready for decision" do
        expect(subject).to eq("RFD")
      end
    end

    context "board remand" do
      let(:code) { "040BDENR" }
      it "returns ready for decision" do
        expect(subject).to eq("RFD")
      end
    end
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

    context "when a Veteran's address is updated after initially fetching the BGS record" do
      it "uses the new address for establishing a claim" do
        # first fetch Veteran's info
        expect(veteran.to_vbms_hash).to include(address_line1: "1234 FAKE ST")
        Fakes::BGSService.edit_veteran_record(veteran.file_number, :address_line1, "Changed")
        subject

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: Veteran::BENEFIT_TYPE_CODE_DEATH,
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            end_product_modifier: "030",
            end_product_code: "030HLRR",
            end_product_label: "Higher-Level Review Rating",
            station_of_jurisdiction: "397",
            date: 2.days.ago.to_date,
            suppress_acknowledgement_letter: false,
            gulf_war_registry: false,
            claimant_participant_id: "11223344",
            limited_poa_code: "ABC",
            limited_poa_access: true,
            status_type_code: "PEND"
          },
          veteran_hash: hash_including(address_line1: "Changed"),
          user: current_user
        )
      end
    end

    context "when eps with a valid modifier already exists" do
      let!(:past_created_ep) do
        Generators::EndProduct.build(
          veteran_file_number: veteran_file_number,
          bgs_attrs: { end_product_type_code: "030", status_type_code: "PEND" }
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
            claimant_participant_id: "11223344",
            limited_poa_code: "ABC",
            limited_poa_access: true,
            status_type_code: "PEND"
          },
          veteran_hash: veteran.reload.to_vbms_hash,
          user: current_user
        )
        expect(end_product_establishment.reload).to have_attributes(
          modifier: "031"
        )
      end

      context "when it is a correction end product" do
        let(:code) { "930AMABGRC" }

        it "creates an end product with the correction valid modifier" do
          subject
          expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
            claim_hash: {
              benefit_type_code: Veteran::BENEFIT_TYPE_CODE_DEATH,
              payee_code: "00",
              predischarge: false,
              claim_type: "Claim",
              end_product_modifier: "930",
              end_product_code: "930AMABGRC",
              end_product_label: "AMA BVA Grant Rating Control",
              station_of_jurisdiction: "397",
              date: 2.days.ago.to_date,
              suppress_acknowledgement_letter: false,
              gulf_war_registry: false,
              claimant_participant_id: "11223344",
              limited_poa_code: "ABC",
              limited_poa_access: true,
              status_type_code: "PEND"
            },
            veteran_hash: veteran.reload.to_vbms_hash,
            user: current_user
          )
          expect(end_product_establishment.reload).to have_attributes(
            modifier: "930"
          )
        end
      end

      context "when invalid modifiers is set" do
        let(:invalid_modifiers) { ["031"] }

        it "creates an ep with the next valid modifier" do
          subject
          expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
            claim_hash: hash_including(
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
              claimant_participant_id: "11223344",
              limited_poa_code: "ABC",
              limited_poa_access: true,
              status_type_code: "PEND"
            ),
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
            bgs_attrs: { end_product_type_code: modifier, status_type_code: "PEND" }
          )
        end
      end

      it "returns NoAvailableModifiers error" do
        expect { subject }.to raise_error(EndProductModifierFinder::NoAvailableModifiers)
      end
    end

    context "when a previous establishment attempt actually succeeded" do
      it "recovers and saves the previous EP" do
        allow(source).to receive(:previously_attempted?).and_return(true)
        allow(end_product_establishment.veteran).to receive(:end_products).and_return([orphaned_end_product])
        subject
        expect(Fakes::VBMSService).not_to have_received(:establish_claim!)
        expect(end_product_establishment).to have_attributes(
          reference_id: orphaned_end_product.claim_id,
          established_at: Time.zone.now,
          modifier: orphaned_end_product.modifier
        )
      end
    end

    context "when existing EP has status CLR" do
      let(:setups) do
        [
          { modifier: "030", last_action_date: 2.weeks.ago.mdY },
          { modifier: "031", last_action_date: 2.weeks.ago.mdY },
          { modifier: "032", last_action_date: 2.weeks.ago.mdY }
        ]
      end

      before do
        setups.each do |setup|
          Generators::EndProduct.build(
            veteran_file_number: veteran_file_number,
            bgs_attrs: {
              end_product_type_code: setup[:modifier],
              last_action_date: setup[:last_action_date],
              status_type_code: "CLR"
            }
          )
        end
      end

      it "considers those EP modifiers as open" do
        subject
        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          hash_including(veteran_hash: veteran.reload.to_vbms_hash)
        )
      end

      context "when last action date is within the last two days" do
        let(:setups) do
          [
            { modifier: "030", last_action_date: 1.day.ago.mdY },
            { modifier: "031", last_action_date: 1.day.ago.mdY },
            { modifier: "032", last_action_date: Time.zone.today.mdY }
          ]
        end

        it "considers those EP modifiers as taken and returns a NoAvailableModifiers error" do
          expect { subject }.to raise_error(EndProductModifierFinder::NoAvailableModifiers)
        end
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
            suppress_acknowledgement_letter: false,
            limited_poa_code: "ABC",
            limited_poa_access: true,
            status_type_code: "PEND"
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
          decision_review: source,
          contested_rating_issue_reference_id: "reference-id",
          contested_rating_issue_profile_date: rating_profile_date,
          contested_issue_description: "this is a big decision"
        ),
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          decision_review: source,
          contested_rating_decision_reference_id: "rating-decision-diagnostic-id",
          contested_rating_issue_profile_date: rating_profile_date,
          contested_issue_description: "foobar was denied."
        ),
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          decision_review: source,
          contested_rating_issue_reference_id: "reference-id",
          contested_rating_issue_profile_date: rating_profile_date,
          vacols_id: vacols_id,
          vacols_sequence_id: vacols_sequence_id,
          contested_issue_description: "more decisionz"
        ),
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          decision_review: source,
          contested_rating_issue_reference_id: "reference-id",
          contested_rating_issue_profile_date: rating_profile_date,
          contested_issue_description: "description too long for bgs" * 20
        ),
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          is_unidentified: true,
          unidentified_issue_text: "identity unknown",
          decision_review: source,
          contested_rating_issue_reference_id: "reference-id",
          contested_rating_issue_profile_date: rating_profile_date
        )
      ]
    end

    let(:contentions) do
      request_issues.map do |issue|
        contention = { description: issue.contention_text, contention_type: issue.contention_type }
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
        user: current_user,
        claim_date: 2.days.ago.to_date
      )

      expect(end_product_establishment.contentions.count).to eq(request_issues.count)
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
              special_issues: [{ code: "SSR", narrative: "Same Station Review" }],
              contention_type: Constants.CONTENTION_TYPES.higher_level_review },
            description: "more decisionz",
            contention_type: Constants.CONTENTION_TYPES.higher_level_review,
            special_issues: array_including(
              { code: "SSR", narrative: "Same Station Review" },
              code: "ASSOI", narrative: Constants.VACOLS_DISPOSITIONS_BY_ID.O
            )
          ),
          user: current_user,
          claim_date: 2.days.ago.to_date
        )
      end
    end

    context "when issues are from dta decisions" do
      let!(:prior_request_issues) do
        [
          create(:request_issue, contention_reference_id: "101"),
          create(:request_issue, contention_reference_id: "121")
        ]
      end

      let!(:dta_decision_issue) do
        create(:decision_issue, request_issues: prior_request_issues, disposition: "DTA Error")
      end

      let!(:request_issues) do
        [
          create(
            :request_issue,
            end_product_establishment: end_product_establishment,
            decision_review: source,
            contested_decision_issue: dta_decision_issue,
            contested_issue_description: "I am contesting a dta decision"
          )
        ]
      end

      context "when send send_original_dta_contentions is enabled" do
        before { FeatureToggle.enable!(:send_original_dta_contentions) }

        it "sends the original contention ids when creating the contention" do
          subject

          expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
            veteran_file_number: veteran_file_number,
            claim_id: end_product_establishment.reference_id,
            contentions: array_including(
              description: "I am contesting a dta decision",
              original_contention_ids: [101, 121],
              contention_type: Constants.CONTENTION_TYPES.higher_level_review
            ),
            user: current_user,
            claim_date: 2.days.ago.to_date
          )
        end
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
            decision_review: source,
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
            decision_review: source,
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

    context "request issue is rating via rating decision" do
      let!(:request_issues) do
        [
          create(
            :request_issue,
            end_product_establishment: end_product_establishment,
            decision_review: source,
            contested_rating_decision_reference_id: "rating-decision-diagnostic-id",
            contested_rating_issue_profile_date: rating_profile_date,
            contested_issue_description: "foobar was denied."
          )
        ]
      end

      it "skips mapping since there is no associated rating issue" do
        subject
        expect(request_issues.first.rating?).to be true
        expect(Fakes::VBMSService).to_not have_received(:associate_rating_request_issues!)
      end
    end

    context "request issue is rating but has no associated_rating_issue" do
      let!(:request_issues) do
        [
          create(
            :request_issue,
            contested_rating_issue_reference_id: nil,
            end_product_establishment: end_product_establishment,
            decision_review: source,
            contention_reference_id: contention_ref_id,
            contested_decision_issue_id: decision_issue.id
          )
        ]
      end
      let(:original_request_issue) do
        create(
          :request_issue,
          decision_review: previous_review,
          contested_rating_issue_reference_id: "123"
        )
      end
      let(:decision_issue) do
        create(:decision_issue,
               decision_review: previous_review,
               request_issues: [original_request_issue])
      end
      let(:previous_review) { create(:higher_level_review) }

      it "skips rating request issues with no associated rating issue" do
        subject
        expect(request_issues.first.rating?).to be true
        expect(Fakes::VBMSService).to_not have_received(:associate_rating_request_issues!)
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

  context "#rating?" do
    subject { end_product_establishment.rating? }
    context "when the end product code is a rating code" do
      let(:code) { "030HLRRPMC" }
      it { is_expected.to be true }
    end

    context "when the end product code is not rating code" do
      let(:code) { "Something" }
      it { is_expected.to be_falsey }
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

    let!(:request_issues) do
      [
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          decision_review: source
        )
      ]
    end

    context "when matching end product has not yet been established" do
      it "raises EstablishedEndProductNotFound error" do
        expect { subject }.to raise_error(EndProductEstablishment::EstablishedEndProductNotFound)
      end
    end

    context "when a matching end product has been established" do
      let(:reference_id) { matching_ep.claim_id }
      let(:status_type_code) { "CLR" }
      let(:claim_type_code) { "030HLRR" }
      let!(:matching_ep) do
        Generators::EndProduct.build(
          veteran_file_number: veteran_file_number,
          bgs_attrs: { status_type_code: status_type_code, claim_type_code: claim_type_code }
        )
      end

      context "returns true if inactive" do
        let(:synced_status) { EndProduct::INACTIVE_STATUSES.first }

        it { is_expected.to eq(true) }
      end

      context "when BGS throws an error" do
        before do
          allow_any_instance_of(BGSService).to receive(:get_end_products).and_raise(BGS::ShareError.new("E"))
        end

        it "re-raises error" do
          expect { subject }.to raise_error(BGS::ShareError)
        end
      end

      context "when the claim_type_code has changed outside of Caseflow" do
        let(:claim_type_code) { "040SCNR" }

        it "creates a record of the change in end product code updates" do
          subject

          epcu = end_product_establishment.end_product_code_updates.first

          expect(end_product_establishment.code).to eq "030HLRR"
          expect(epcu.code).to eq "040SCNR"
          expect(epcu.created_at).to eq(Time.zone.now)
        end

        context "when the new claim_type_code has already been saved" do
          it "does not create a new record" do
            end_product_establishment.end_product_code_updates.create(code: "040SCNR", created_at: 1.hour.ago)

            subject

            epcus = end_product_establishment.end_product_code_updates
            expect(epcus.count).to eq 1
            expect(epcus.first.created_at).to eq 1.hour.ago
          end
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

      context "when the end product has been cleared and no decision issues are expected" do
        let(:status_type_code) { "CLR" }
        let(:claim_type_code) { "400RA" }

        it "closes request issues with no_decision" do
          subject

          expect(end_product_establishment.reload.synced_status).to eq("CLR")
          expect(request_issues.first.reload.closed_at).to eq(Time.zone.now)
          expect(request_issues.first.closed_status).to eq("no_decision")
        end
      end

      context "when the end product is canceled" do
        before { allow(Fakes::VBMSService).to receive(:fetch_contentions).and_call_original }
        let(:status_type_code) { EndProduct::STATUSES.key("Canceled") }

        it "closes request issues, cancels establishment, and doesn't fetch contentions" do
          subject

          expect(Fakes::VBMSService).to_not have_received(:fetch_contentions)
          expect(end_product_establishment.reload.synced_status).to eq("CAN")
          expect(end_product_establishment.source.canceled?).to be true
          expect(request_issues.first.reload.closed_at).to eq(Time.zone.now)
          expect(request_issues.first.closed_status).to eq("end_product_canceled")
        end
      end

      it "updates last_synced_at and synced_status" do
        subject
        expect(end_product_establishment.reload.last_synced_at).to eq(Time.zone.now)
        expect(end_product_establishment.reload.synced_status).to eq("CLR")
      end
    end
  end

  context "#cancel_unused_end_product!" do
    subject { end_product_establishment.cancel_unused_end_product! }
    let(:closed_at) { nil }
    let!(:request_issues) do
      [
        create(
          :request_issue,
          end_product_establishment: end_product_establishment,
          decision_review: source,
          closed_at: closed_at
        )
      ]
    end

    context "when there are no active request issues" do
      let(:closed_at) { 1.day.ago }

      it "cancels the end product" do
        subject
        expect(end_product_establishment.reload.synced_status).to eq("CAN")
      end

      context "#returns cancel_end_product parameters!" do
        let!(:modifier) { "030" }
        let(:benefit_type_code) { Veteran::BENEFIT_TYPE_CODE_LIVE }
        let(:end_product_establishment) do
          EndProductEstablishment.new(
            source: source,
            veteran_file_number: veteran_file_number,
            code: code,
            payee_code: payee_code,
            claim_date: 2.days.ago,
            benefit_type_code: benefit_type_code,
            modifier: modifier,
            reference_id: "1",
            synced_status: synced_status,
            last_synced_at: last_synced_at
          )
        end

        let!(:bgs_service) { BGSService.new }

        before do
          allow(BGSService).to receive(:new) { bgs_service }
          allow(bgs_service).to receive(:cancel_end_product).and_call_original
        end

        it do
          subject
          expect(bgs_service).to have_received(:cancel_end_product).once.with(veteran_file_number,
                                                                              code, modifier,
                                                                              payee_code,
                                                                              benefit_type_code)
        end
      end
    end

    context "when source is a RampReview" do
      let(:source) { create(:ramp_election) }
      it "does nothing" do
        expect(subject).to be_nil
        expect(end_product_establishment.reload.synced_status).to be_nil
        expect(request_issues.first.closed_status).to be_nil
      end
    end

    context "when there are still active request issues" do
      it "does nothing" do
        expect(subject).to be_nil
        expect(end_product_establishment.reload.synced_status).to be_nil
        expect(request_issues.first.closed_status).to be_nil
      end
    end
  end

  context "#status_cancelled?" do
    subject { end_product_establishment.status_cancelled? }

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
      Generators::PromulgatedRating.build(
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
          Generators::PromulgatedRating.build(
            profile_date: end_product_establishment.established_at + 1.day,
            participant_id: veteran.participant_id,
            promulgation_date: end_product_establishment.established_at + 1.day,
            associated_claims: []
          )
        end
        let(:promulgation_date) { end_product_establishment.established_at - 1.day }

        it { is_expected.to eq(nil) }
      end
    end

    context "when many potential ratings" do
      let(:reference_id) { "reference-id" }
      let(:other_epe) do
        create(
          :end_product_establishment,
          veteran_file_number: veteran_file_number,
          established_at: end_product_establishment.established_at + 2.days,
          code: "040SCR"
        )
      end

      let(:associated_claims) do
        [
          { clm_id: "09123", bnft_clm_tc: end_product_establishment.code },
          { clm_id: end_product_establishment.reference_id, bnft_clm_tc: end_product_establishment.code },
          { clm_id: "09321", bnft_clm_tc: other_epe.code },
          { clm_id: other_epe.reference_id, bnft_clm_tc: other_epe.code }
        ]
      end

      let(:ratings) do
        [
          rating,
          Generators::PromulgatedRating.build(
            participant_id: veteran.participant_id,
            promulgation_date: promulgation_date + 2.days,
            associated_claims: associated_claims
          )
        ]
      end

      let(:cache_key) { end_product_establishment.associated_rating_cache_key }

      before do
        end_product_establishment.save!
      end

      it "caches the associated rating for the given EPE" do
        expect(Rails.cache.exist?(cache_key)).to eq(false)
        # If caching works, this should only get called once
        expect(RatingAtIssue).to receive(:fetch_in_range).once.and_call_original
        subject
        expect(Rails.cache.exist?(cache_key)).to eq(true)
        # when called a second time, should get from cache
        subject
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
      let(:rating_issue) do
        create(
          :request_issue,
          :rating,
          end_product_establishment: end_product_establishment,
          decision_review: source,
          decision_sync_submitted_at: nil
        )
      end
      let(:nonrating_issue) do
        create(
          :request_issue,
          :nonrating,
          end_product_establishment: end_product_establishment,
          decision_review: source,
          decision_sync_submitted_at: nil
        )
      end
      let!(:request_issues) { [rating_issue, nonrating_issue] }

      it "submits each request issue and starts decision sync job" do
        subject

        # delay in processing should be 1 day for rating (minus the processing offset of 12.hours)
        expect(rating_issue.reload.decision_sync_submitted_at).to eq(Time.zone.now)
        expect(rating_issue.reload.decision_sync_last_submitted_at).to eq(
          Time.zone.now + RequestIssue.processing_retry_interval_hours.hours
        )
        # immediatly for nonrating
        expect(nonrating_issue.reload.decision_sync_submitted_at).to eq(Time.zone.now)

        expect(DecisionIssueSyncJob).to_not have_been_enqueued.with(rating_issue)
        expect(DecisionIssueSyncJob).to have_been_enqueued.with(nonrating_issue)
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

        # delay in processing should be 1 day (minus the processing offset of 12.hours)
        expect(board_grant_effectuation.reload.decision_sync_submitted_at).to eq(Time.zone.now)
        expect(board_grant_effectuation.reload.decision_sync_last_submitted_at).to eq(
          Time.zone.now + BoardGrantEffectuation.processing_retry_interval_hours.hours
        )
        expect(DecisionIssueSyncJob).to_not have_been_enqueued.with(board_grant_effectuation)
      end
    end
  end

  context "#on_decision_issue_sync_processed" do
    subject { end_product_establishment.on_decision_issue_sync_processed(processing_request_issue) }
    let(:processed_at) { Time.zone.now }

    let(:processing_request_issue) do
      create(:request_issue, decision_review: source)
    end

    let!(:processed_request_issue) do
      create(:request_issue, decision_review: source, decision_sync_processed_at: Time.zone.now)
    end

    let!(:closed_request_issue) do
      create(:request_issue, :removed, decision_review: source)
    end

    context "when decision issues are all synced" do
      context "when source is a higher level review" do
        let!(:claimant) do
          VeteranClaimant.create!(
            decision_review: source,
            participant_id: veteran.participant_id,
            payee_code: "10"
          )
        end

        let!(:decision_issue) do
          create(:decision_issue,
                 decision_review: source,
                 disposition: DecisionIssue::DTA_ERROR_PMR,
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
      let!(:not_processed_request_issue) do
        create(:request_issue, decision_review: source)
      end

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

          let(:pending_request_issue) do
            create(
              :request_issue,
              decision_review: epe.source,
              end_product_establishment: epe
            )
          end

          it { is_expected.to eq(ep_code: "037 Higher-Level Review Rating", ep_status: "Cleared") }

          context "when there are pending request issues to sync" do
            let!(:pending_request_issue) do
              create(
                :request_issue,
                decision_review: epe.source,
                end_product_establishment: epe,
                decision_sync_submitted_at: Time.zone.now + 1.second
              )
            end

            it do
              is_expected.to eq(ep_code: "037 Higher-Level Review Rating",
                                ep_status: "Cleared, Syncing decisions...")
            end

            context "when there are pending request issues to sync with errors" do
              let!(:errored_request_issue) do
                create(
                  :request_issue,
                  decision_review: epe.source,
                  end_product_establishment: epe,
                  decision_sync_submitted_at: Time.zone.now,
                  decision_sync_error: "oh no"
                )
              end

              it do
                is_expected.to eq(
                  ep_code: "037 Higher-Level Review Rating",
                  ep_status: "Cleared, Decisions sync failed. Support notified."
                )
              end
            end
          end

          context "when there are closed request issues with no decision" do
            let!(:closed_request_issue) do
              create(
                :request_issue,
                decision_review: epe.source,
                end_product_establishment: epe,
                decision_sync_submitted_at: Time.zone.now,
                decision_sync_processed_at: nil,
                closed_status: "no_decision",
                closed_at: Time.zone.now
              )
            end

            it do
              binding.pry
              is_expected.to eq(
                ep_code: "037 Higher-Level Review Rating",
                ep_status: "Cleared"
              )
            end
          end
        end
      end

      context "if there is no modifier, shows unknown" do
        it { is_expected.to eq(ep_code: " Higher-Level Review Rating", ep_status: "") }
      end

      context "if the epe code is not found" do
        before { epe.update!(code: "NOTFOUND") }

        it { is_expected.to eq(ep_code: " Unknown", ep_status: "") }
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
