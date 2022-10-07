RSpec.describe SplitAppealController, :postgres do
  let(:user_css_id) { "SPLTAPPLSNOW" }
  let(:appeal_id) { "1" }
  let(:split_issue) { "Some Split Issue" }
  let(:split_other_reason) { "Some split_other_reason" }
  let(:split_reason) { "Some split_other_reason" }
  let(:appeal) { Appeal.find(appeal_id) }

  it "Will split the appeal on click" do
    let(FeatureToggle.enabled?(:split_appeal_workflow)) == True;
    let(:user_css_id) { "SPLTAPPLSNOW" }
    let(:appeal_id) { "1" }
    let(:split_issue) { "Some Split Issue" }
    let(:split_other_reason) { "Some split_other_reason" }
    let(:split_reason) { "Some split_other_reason" }
    let(:appeal) { Appeal.find(appeal_id) }
    let(:dup_appeal) { appeal.amoeba_dup }
    expect(dup_appeal).not_to be_(appeal_id)
  end
end
