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
      subject

      expect(intake.reload).to be_canceled
      expect { detail.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(intake).to have_attributes(
        cancel_reason: "system_error",
        cancel_other: nil
      )
    end
  end

  context "#complete!" do
    subject { intake.complete!(params) }

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
      expect(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original

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
      it "returns nil" do
        expect(Fakes::VBMSService).not_to receive(:establish_claim!)
        expect(Fakes::VBMSService).not_to receive(:create_contentions!)
      end
    end
  end
end
