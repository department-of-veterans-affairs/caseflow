# frozen_string_literal: true

# rubocop:disable Layout/LineLength

describe Events::DecisionReviewCreated::CreateIntake do
  context "Events::DecisionReviewCreated::CreateIntake.process!" do
    let(:event_double) { double("Event") }
    let(:user_double) { double("User") }
    let(:veteran_double) { double("Veteran", file_number: "DCR02272024", id: "2000932150") }
    let(:parser) { Events::DecisionReviewCreated::DecisionReviewCreatedParser.load_example }
    let(:intake_double) { double("Intake") }
    let(:event_record_double) { double("EventRecord") }
    let(:decision_review_double) { double("DecisionReview", id: "1") }

    it "creates an intake and event record" do
      allow(Intake).to receive(:create!).and_return(intake_double)
      allow(EventRecord).to receive(:create!).and_return(event_record_double)
      expect(Intake).to receive(:create!).with(veteran_file_number: "DCR02272024",
                                               user: user_double,
                                               started_at: parser.intake_started_at,
                                               completion_started_at: parser.intake_completion_started_at,
                                               completed_at: parser.intake_completed_at,
                                               completion_status: parser.intake_completion_status,
                                               type: parser.intake_type,
                                               detail_type: parser.intake_detail_type,
                                               detail_id: decision_review_double.id,
                                               veteran: veteran_double)
        .and_return(intake_double)
      expect(EventRecord).to receive(:create!).with(event: event_double, evented_record: intake_double)
        .and_return(event_record_double)
      described_class.process!(event: event_double, user: user_double, veteran: veteran_double, parser: parser,
                               decision_review: decision_review_double)
    end
    context "when an error occurs" do
      # rubocop:disable Layout/MultilineBlockLayout, Style/BlockDelimiters
      it "raises the error" do
        allow(Intake).to receive(:create!).and_raise(Caseflow::Error::DecisionReviewCreatedIntakeError)
        expect { described_class.process!(event: event_double, user: user_double, veteran: veteran_double, parser: parser,
                                          decision_review: decision_review_double)
        }.to raise_error(Caseflow::Error::DecisionReviewCreatedIntakeError)
      end
      # rubocop:enable Layout/MultilineBlockLayout, Style/BlockDelimiters
    end
  end
end

# rubocop:enable Layout/LineLength
