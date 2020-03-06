# frozen_string_literal: true

RSpec.describe ApplicationHelper, type: :helper do
  describe "#current_ga_path" do
    it "returns route's path without resource ids" do
      helper.request.env["PATH_INFO"] = "/certifications/new/123C"
      expect(helper.current_ga_path).to eq "/certifications/new"
    end

    it "returns route's path when method is POST" do
      helper.request.env["PATH_INFO"] = "/certifications/123C/confirm"
      helper.request.env["REQUEST_METHOD"] = "POST"
      expect(helper.current_ga_path).to eq "/certifications/confirm"
    end
  end
end
