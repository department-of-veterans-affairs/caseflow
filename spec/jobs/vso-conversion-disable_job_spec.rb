describe VSOConversionDisable, :postgres do
  let(:hearing_day) { create(:hearing_day, scheduled_for: "")}
  let(:hearing) { create(:hearing, scheduled_time: "") }
  context "when there's no hearings 11 days before scheduled" do
    subject { find_affected_hearings(hearing_docket) }

    it "find_affected_hearings returns empty array" do

    end
  end
  context "when there are hearings 11 days before scheduled" do
    subject { find_affected_hearings(hearing_docket) }

    it "find_affected_hearings returns relevant hearing" do

    end
  end
end