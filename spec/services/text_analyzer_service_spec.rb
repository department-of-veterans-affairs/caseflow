# frozen_string_literal: true

RSpec.describe TextAnalyzerService do
  let(:mock_response_data) do
    [
      {
        Score: 0.9825336337089539,
        Text: "Department",
        BeginOffset: 1,
        EndOffset: 11
      },
      {
        Score: 0.9576260447502136,
        Text: "Veterans Affairs\nCERTIFICATION",
        BeginOffset: 15,
        EndOffset: 45
      },
      {
        Score: 0.994326651096344,
        Text: "APPEAL\n1A",
        BeginOffset: 49,
        EndOffset: 58
      },
      {
        Score: 0.9341291785240173,
        Text: "APPELLANT",
        BeginOffset: 68,
        EndOffset: 77
      }
    ]
  end

  let(:mock_comprehend_client) do
    instance_double("Aws::Comprehend::Client", detect_entities: mock_response_data)
  end

  let(:text_analyzer_service) { TextAnalyzerService.new(mock_comprehend_client) }

  describe "#analyze" do
    it "returns mock response for detect_entities" do
      text = "Sample text for AWS Comprehend"
      response = text_analyzer_service.analyze(text)

      expect(response).to eq(mock_response_data)
    end

    it "returns empty response for empty text" do
      text = ""
      response = text_analyzer_service.analyze(text)

      expect(response).to be_empty
    end

    it "handles nil text and returns empty response" do
      text = nil
      response = text_analyzer_service.analyze(text)

      expect(response).to be_empty
    end

  end
end
