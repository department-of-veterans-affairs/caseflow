describe JudgeSchedulePeriod do
  let(:judge_schedule_period) { create(:judge_schedule_period) }
  let(:user) { create(:default_user) }

  before do
    user.save!
  end

  context "validate_spreadsheet" do
    before do
      S3Service.store_file(judge_schedule_period.file_name, "spec/support/validJudgeSpreadsheet.xlsx", :filepath)
    end

    subject { judge_schedule_period.validate_spreadsheet }

    it { is_expected.to be_truthy }
  end
end
