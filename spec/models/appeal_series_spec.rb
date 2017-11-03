describe AppealSeries do
  let(:original) do
    Generators::Appeal.build(
      id: 1,
      vbms_id: vbms_id,
      type: "Original",
      decision_date: 365.days.ago
    )
  end

  let(:vbms_id) { "111223333S" }

  context ".appeal_series_by_vbms_id" do
    it "uses existing appeal series when possible" do
      expect(original.appeal_series).to be_nil
      series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
      expect(series.length).to eq 1
      expect(original.reload.appeal_series).to eq series.first
      original.appeal_series.update(incomplete: true)
      AppealSeries.appeal_series_by_vbms_id(vbms_id)
      expect(original.reload.appeal_series.incomplete).to be true
    end

    it "regenerates appeal series if a new appeal has been added" do
    end

    it "regenerates appeal series if an appeal has been merged" do
    end

    context "matching on folder number for post-remand field dispositions" do
    end

    context "matching on prior decision date" do
    end

    context "matching on issues" do
    end

    context "merging appeals" do
    end
  end
end
