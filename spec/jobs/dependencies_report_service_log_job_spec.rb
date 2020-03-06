# frozen_string_literal: true

describe DependenciesReportServiceLogJob do
  DEPENDENCIES_REPORT_WITH_OUTAGES = <<-'EOF'.strip_heredoc.freeze
    {
      "BGS":{"name":"BGS","up_rate_5":100.0},
      "VACOLS":{"name":"VACOLS","up_rate_5":10.0},
      "VBMS":{"name":"VBMS","up_rate_5":49.0},
      "VBMS.FindDocumentVersionReference":{"name":"VBMS.FindDocumentVersionReference",
        "up_rate_5":100.0}
    }
  EOF
  DEPENDENCIES_REPORT_WITH_INVALID_DATA = <<-'EOF'.strip_heredoc.freeze
    {
      "BGS":{"name":"BGS","bad_field":"a"},
    }
  EOF

  context "when outage is present" do
    before do
      Rails.cache.write(:dependencies_report, DEPENDENCIES_REPORT_WITH_OUTAGES)
    end

    it "should log the correct error message" do
      expect(Rails.logger).to receive(:error).with("Caseflow Monitor shows a possible VACOLS and VBMS outage(s).")
      DependenciesReportServiceLogJob.perform_now
    end
  end

  context "when report is invalid" do
    before do
      Rails.cache.write(:dependencies_report, DEPENDENCIES_REPORT_WITH_INVALID_DATA)
    end
    it "should log the correct error message" do
      expect(Rails.logger).to receive(:error).with("Invalid report from Caseflow Monitor")
      DependenciesReportServiceLogJob.perform_now
    end
  end
end
