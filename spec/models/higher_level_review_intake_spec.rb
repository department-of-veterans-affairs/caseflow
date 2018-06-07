describe HigherLevelReviewIntake do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
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

  context "#start!" do
    subject { intake.start! }

    context "intake is already in progress by same user" do
      it "should not create another intake" do
        HigherLevelReviewIntake.new(
          user: user,
          veteran_file_number: veteran_file_number
        ).start!

        expect(intake).to_not be_nil
        expect(subject).to eq(false)
      end
    end
  end

  context "#cancel!" do
    subject { intake.cancel!(reason: "system_error", other: nil) }

    let(:detail) do
      HigherLevelReview.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    it "cancels and deletes the Higher Level Review record created" do
      detail.create_claimants!(claimant_data: "1234")

      subject

      expect(intake.reload).to be_canceled
      # expect { detail.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(intake).to have_attributes(
        cancel_reason: "system_error",
        cancel_other: nil
      )
      expect(Claimant.find_by(participant_id: "1234")).to be_nil
    end
  end

  context "#complete!" do
    subject { intake.complete!(params) }

    before do
      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
    end

    let(:params) do
      { request_issues: [
        { profile_date: "2018-04-30", reference_id: "reference-id", decision_text: "decision text" }
      ] }
    end

    let(:detail) do
      HigherLevelReview.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    it "completes the intake and creates an end product" do
      subject

      expect(intake.reload).to be_success
      expect(intake.detail.established_at).to_not be_nil
      expect(intake.detail.end_product_reference_id).to_not be_nil
      expect(intake.detail.request_issues.count).to eq 1
      expect(intake.detail.request_issues.first).to have_attributes(
        rating_issue_reference_id: "reference-id",
        rating_issue_profile_date: Date.new(2018, 4, 30),
        description: "decision text"
      )
      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: intake.detail.veteran_file_number,
        claim_id: intake.detail.end_product_reference_id,
        contention_descriptions: ["decision text"]
      )
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
            end_product_label: "Higher Level Review Rating",
            end_product_code: "030HLRR",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false
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
          :create_end_product_and_contentions!
        ).and_raise(unknown_error)

        expect { subject }.to raise_exception
        expect(intake.completion_status).to be_nil
      end
    end
  end
end
