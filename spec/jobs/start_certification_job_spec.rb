# frozen_string_literal: true

describe StartCertificationJob, :all_dbs do
  let(:appeal) do
    create(:legacy_appeal, vacols_case: vacols_case)
  end

  let(:vacols_case) do
    create(:case_with_ssoc)
  end

  let(:certification) do
    create(:certification, vacols_case: vacols_case, loading_data: true)
  end

  let(:certification_missing_data) do
    create(:certification, vacols_id: "FAKE_ID_WITH_NO_DATA", loading_data: true)
  end

  context ".perform" do
    it "indicates when starting certification is successful" do
      StartCertificationJob.perform_now(certification)

      expect(certification.loading_data).to eq(false)
      expect(certification.loading_data_failed).to eq(false)
    end

    it "indicates when starting certification failed" do
      StartCertificationJob.perform_now(certification_missing_data)

      expect(certification_missing_data.loading_data_failed).to eq(true)
    end
  end
end
