describe EndProductEstablishment do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))

    if source.is_a?(HigherLevelReview)
      source.stub(:valid_modifiers).and_return(%w[030 031 032])
      source.stub(:invalid_modifiers).and_return(invalid_modifiers)
      source.stub(:special_issues).and_return(special_issues)
    end
  end

  let(:veteran_file_number) { "12341234" }
  let(:veteran_participant_id) { "11223344" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number, participant_id: veteran_participant_id) }
  let(:code) { "030HLRR" }
  let(:payee_code) { "00" }
  let(:reference_id) { nil }
  let(:source) { HigherLevelReview.new(veteran_file_number: veteran_file_number) }
  let(:invalid_modifiers) { nil }
  let(:synced_status) { nil }
  let(:special_issues) { nil }
  let(:committed_at) { nil }

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
      committed_at: committed_at
    )
  end

  let(:vbms_error) do
    VBMS::HTTPError.new("500", "More EPs more problems")
  end

  context "#perform!" do
    subject { end_product_establishment.perform! }

    before do
      Fakes::VBMSService.end_product_claim_ids_by_file_number ||= {}
      Fakes::VBMSService.end_product_claim_ids_by_file_number[veteran.file_number] = "FAKECLAIMID"
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
            benefit_type_code: "1",
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
          veteran_hash: veteran.to_vbms_hash
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
              benefit_type_code: "1",
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
            veteran_hash: veteran.to_vbms_hash
          )
          expect(end_product_establishment.reload).to have_attributes(
            modifier: "032"
          )
        end
      end
    end

    context "when all goes well" do
      it "creates end product and sets reference_id" do
        subject

        expect(end_product_establishment.reload).to have_attributes(
          reference_id: "FAKECLAIMID",
          veteran_file_number: veteran_file_number,
          established_at: Time.zone.now,
          committed_at: nil,
          modifier: "030"
        )

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
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
          veteran_hash: veteran.to_vbms_hash
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

    subject { end_product_establishment.create_contentions!(for_objects) }

    let(:reference_id) { "stevenasmith" }

    let(:for_objects) do
      [
        RequestIssue.new(
          review_request: source,
          rating_issue_reference_id: "reference-id",
          rating_issue_profile_date: Date.new(2018, 4, 30),
          description: "this is a big decision"
        ),
        RequestIssue.new(
          review_request: source,
          rating_issue_reference_id: "reference-id",
          rating_issue_profile_date: Date.new(2018, 4, 30),
          description: "more decisionz"
        )
      ]
    end

    it "creates contentions and saves them to objects" do
      subject

      expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
        veteran_file_number: veteran_file_number,
        claim_id: end_product_establishment.reference_id,
        contention_descriptions: ["this is a big decision", "more decisionz"],
        special_issues: []
      )

      expect(end_product_establishment.contentions.map(&:id)).to contain_exactly(
        *for_objects.map(&:reload).map(&:contention_reference_id)
      )
    end

    context "when source has special issues" do
      let(:special_issues) { "SPECIALISSUES!" }

      it "sets special issues when creating the contentions" do
        subject

        expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
          veteran_file_number: veteran_file_number,
          claim_id: end_product_establishment.reference_id,
          contention_descriptions: ["this is a big decision", "more decisionz"],
          special_issues: "SPECIALISSUES!"
        )
      end
    end
  end

  context "commit!" do
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

    let(:for_object) do
      RequestIssue.new(
        review_request: source,
        rating_issue_reference_id: "reference-id",
        rating_issue_profile_date: Date.new(2018, 4, 30),
        description: "this is a big decision",
        contention_reference_id: "skipbayless"
      )
    end

    let!(:contention) do
      Generators::Contention.build(id: "skipbayless", claim_id: reference_id, text: "Left knee")
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
end
