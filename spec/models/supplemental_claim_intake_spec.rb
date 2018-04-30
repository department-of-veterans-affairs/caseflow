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
    subject { intake.complete!({}) }

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
    end
  end
end
