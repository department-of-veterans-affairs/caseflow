RSpec.describe SplitAppealController, :postgres do
  let(:user_css_id) { "SPLTAPPLSNOW" }
  let(:appeal_id) { "1" }
  let(:split_issue) { "Some Split Issue" }
  let(:split_other_reason) { "Some split_other_reason" }
  let(:split_reason) { "Some split_other_reason" }
  let(:appeal) { Appeal.find(appeal_id) }
  
  describe split_appeal do
    context
      let(FeatureToggle.enabled?(:split_appeal_workflow)) == True;
      let(:user_css_id) { "SPLTAPPLSNOW" }
      let(:appeal_id) { "1" }
      let(:split_issue) { "Some Split Issue" }
      let(:split_other_reason) { "Some split_other_reason" }
      let(:split_reason) { "Some split_other_reason" }
      let(:appeal) { Appeal.find(appeal_id) }
      let(:dup_appeal) { appeal.amoeba_dup }
      if dup_appeal != Appeal.find(appeal_id)
        return success
      else
        return fail
      end
    end
end
