describe SupplementalClaimIntake do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let(:user) { Generators::User.build }
  let(:detail) { nil }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:completed_at) { nil }

  let(:intake) do
    SupplementalClaimIntake.new(
      user: user,
      detail: detail,
      veteran_file_number: veteran_file_number,
      completed_at: completed_at
    )
  end

  context "#cancel!" do
    subject { intake.cancel!(reason: "system_error", other: nil) }

    let(:detail) do
      SupplementalClaim.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    it "cancels and deletes the supplemental claim record created" do
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
        { profile_date: '2018-04-30', reference_id: 'reference-id', decision_text: 'decision text'}
      ]}
    end

    let(:detail) do
      SupplementalClaim.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    it "completes the intake and creates an end product" do
      subject

      expect(intake.reload).to be_success
      expect(intake.detail.established_at).to_not be_nil
      expect(intake.detail.end_product_reference_id).to_not be_nil
      expect(intake.detail.end_product_reference_id).to_not be_nil
      expect(intake.detail.request_issues.count).to eq 1
      expect(intake.detail.request_issues.first).to have_attributes(
        rating_issue_reference_id: 'reference-id',
        rating_issue_profile_date: Date.new(2018, 4, 30),
        description: 'decision text'
      )
    end
  end
end
