# frozen_string_literal: true

describe FetchAllActiveLegacyAppealsJob do
  describe ".perform" do
    subject { FetchAllActiveLegacyAppealsJob.new.perform }
    it "finds all active legacy appeals" do
	  allow()
	  expect_any_instance_of(subject).to receive(:find_all_active_legacy_appeals)
	  subject
    end
  end
end
