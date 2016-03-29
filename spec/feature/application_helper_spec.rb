require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#current_ga_path" do
    it "returns route's path without resource ids" do
      helper.request.env["PATH_INFO"] = "/certifications/new/123C"
      expect(helper.current_ga_path).to eq "/certifications/new"
    end
  end
end
