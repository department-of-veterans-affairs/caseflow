# frozen_string_literal: true

describe FetchEfolderDocumentCountJob do
  describe ".perform" do
    before do
      allow(ExternalApi::EfolderService).to receive(:fetch_document_count) { 10 }

      @emitted_gauges = []
      allow(DataDogService).to receive(:emit_gauge) do |args|
        @emitted_gauges.push(args)
      end
    end

    let(:file_number) { "1234" }
    let(:user) { double(:user) }

    it "calls Efolder API service" do
      doc_count = FetchEfolderDocumentCountJob.perform_now(file_number: file_number, user: user)

      expect(doc_count).to eq(10)
      expect(@emitted_gauges.first).to include(
        app_name: "caseflow_job",
        metric_group: "efolder_fetch_document_count",
        metric_name: "runtime",
        metric_value: anything
      )
    end
  end
end
