# frozen_string_literal: true

describe CorrespondenceAutoAssignmentLever do
  with_versioning do
    it "enables paper trail" do
      is_expected.to be_versioned
    end
  end
end
