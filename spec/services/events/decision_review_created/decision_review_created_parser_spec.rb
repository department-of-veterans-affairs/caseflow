# frozen_string_literal: true

describe Events::DecisionReviewCreated::DecisionReviewCreatedParser do
  # mimic when we recieve an example_response
  context "Events::DecisionReviewCreated::DecisionReviewCreatedParser.load_example" do
    parser = described_class.load_example
    it "has Veteran attributes" do
      expect(parser.veteran_file_number).to be_truthy
      expect(parser.veteran_ssn).to be_truthy
      expect(parser.veteran_first_name).to be_truthy
      expect(parser.veteran_last_name).to be_truthy
      expect(parser.veteran_middle_name).to be_truthy
      expect(parser.veteran_participant_id).to be_truthy
      expect(parser.veteran_bgs_last_synced_at).to be_truthy
      expect(parser).to receive(:veteran_name_suffix).and_return(true)
      # expect(parser.veteran_date_of_death).to be_truthy
      # expect(parser.veteran).to be_truthy
    end
  end
end
