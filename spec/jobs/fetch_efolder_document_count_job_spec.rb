# frozen_string_literal: true

describe FetchEfolderDocumentCountJob do
  describe ".perform" do
    let(:file_number) { "1234" }
    let(:user) { double(:user) }

    subject { FetchEfolderDocumentCountJob.perform_now(file_number: file_number, user: user) }

    before do
      @emitted_gauges = []
      allow(DataDogService).to receive(:emit_gauge) do |args|
        @emitted_gauges.push(args)
      end
    end

    context "success" do
      before do
        allow(ExternalApi::EfolderService).to receive(:fetch_document_count) { 10 }
      end

      it "calls Efolder API service" do
        doc_count = subject

        expect(doc_count).to eq(10)
        expect(@emitted_gauges.first).to include(
          app_name: "caseflow_job",
          metric_group: "fetch_efolder_document_count_job",
          metric_name: "runtime",
          metric_value: anything
        )
      end
    end

    context "eFolder returns error with invalid JSON" do
      before do
        allow(ExternalApi::EfolderService).to receive(:send_efolder_request) do
          HTTPI::Response.new(502, {}, "<head><title>502 Bad Gateway</title></head>")
        end

        allow(Rails.logger).to receive(:error).and_call_original
      end

      it "throws ignorable error" do
        subject

        expect(@emitted_gauges).to eq([])
        expect(Rails.logger).to have_received(:error).once
      end
    end

    context "eFolder returns success with invalid JSON" do
      before do
        allow(ExternalApi::EfolderService).to receive(:send_efolder_request) do
          HTTPI::Response.new(200, {}, "i am not json")
        end
      end

      it "throws JSON error" do
        expect { subject }.to raise_error(JSON::ParserError)
        expect(@emitted_gauges).to eq([])
      end
    end
  end
end
