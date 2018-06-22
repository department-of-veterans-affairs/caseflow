describe JudgeNonAvailability do
  let(:judge_schedule_period) { create(:judge_schedule_period) }

  context ".import_judge_non_availability" do
    before do
      S3Service.store_file(judge_schedule_period.file_name, "spec/support/validJudgeSpreadsheet.xlsx", :filepath)
    end

    it "imports judge non-availability days" do
      expect(JudgeNonAvailability.where(schedule_period: judge_schedule_period).count).to eq(0)
      JudgeNonAvailability.import_judge_non_availability(judge_schedule_period)
      expect(JudgeNonAvailability.where(schedule_period: judge_schedule_period).count).to eq(2)
    end
  end
end
