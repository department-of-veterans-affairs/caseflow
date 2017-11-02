describe AppealSeries do
  let(:original) do
    Generators::Appeal.build(
      vbms_id: vbms_id,
      type: "Original",
      decision_date: 365.days.ago
    )
  end

  let(:vbms_id) { "111223333S" }

  context ".appeal_series_by_vbms_id" do
    subject { AppealSeries.appeal_series_by_vbms_id(*vbms_id) }

    it "uses previous appeal series when possible" do
      expect(original.appeal_series).to be_nil
      series = subject
      expect(series.length).to eq 1
      expect(original.appeal_series).to_not be_nil
      expect(original.appeal_series).to eq series.first
      original.appeal_series.incomplete = true
      subject
      expect(original.appeal_series.incomplete).to be true
    end

    it "regenerates appeal series if a new appeal has been added" do
    end

    it "regenerates appeal series if an appeal has been merged" do
    end
  end

  context ".generate_appeal_series_for_vbms_id" do
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
