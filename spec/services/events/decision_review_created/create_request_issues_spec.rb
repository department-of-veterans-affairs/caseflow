# frozen_string_literal: true

require "json"

describe Events::DecisionReviewCreated::CreateRequestIssues do
  let!(:event) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
  let!(:epe) { create(:end_product_establishment) }
  let!(:higher_level_review) { create(:higher_level_review) }
  let!(:payload) { Events::DecisionReviewCreated::DecisionReviewCreatedParser.example_response }

  describe "#process!" do
    subject { described_class }

    context "when receiving an Event with only request_issues" do
      it "should create CF RequestIssues and backfill records" do
        parser = Events::DecisionReviewCreated::DecisionReviewCreatedParser.new({}, retrieve_payload)

        backfilled_issues = subject.process!(event: event, parser: parser, epe: epe,
                                             decision_review: higher_level_review)

        expect(backfilled_issues.count).to eq(2)
        expect(RequestIssue.count).to eq(2)
        expect(EventRecord.count).to eq(2)
        expect(backfilled_issues.first.event_record).to eq(EventRecord.first)
        expect(backfilled_issues.last.event_record).to eq(EventRecord.last)

        # check if attributes match
        ri1 = backfilled_issues.first
        ri2 = backfilled_issues.last

        expect(ri1.benefit_type).to eq("pension")
        expect(ri1.contested_issue_description).to eq("service connection for arthritis denied")
        expect(ri1.contention_reference_id).to eq(4_542_785)
        expect(ri1.nonrating_issue_category).to eq("DIC")
        expect(ri1.decision_date).to eq(parser.logical_date_converter(20_240_314))
        expect(ri1.nonrating_issue_bgs_id).to eq("12")
        expect(ri1.nonrating_issue_bgs_source).to eq("Test Source")
        expect(ri1.end_product_establishment_id).to eq(epe.id)
        expect(ri1.decision_review_id).to eq(higher_level_review.id)
        expect(ri1.decision_review_type).to eq("HigherLevelReview")
        expect(ri1.veteran_participant_id).to eq(parser.veteran_participant_id)
        expect(ri1.rating_issue_associated_at).to eq(nil)

        expect(ri2.benefit_type).to eq("pension")
        expect(ri2.contested_issue_description).to eq("PTSD")
        expect(ri2.contention_reference_id).to eq(123_456)
        expect(ri2.nonrating_issue_category).to eq(nil)
        expect(ri2.decision_date).to eq(parser.logical_date_converter(20_240_314))
        expect(ri2.nonrating_issue_bgs_id).to eq(nil)
        expect(ri2.nonrating_issue_bgs_source).to eq(nil)
        expect(ri2.end_product_establishment_id).to eq(epe.id)
        expect(ri2.decision_review_id).to eq(higher_level_review.id)
        expect(ri2.decision_review_type).to eq("HigherLevelReview")
        expect(ri2.veteran_participant_id).to eq(parser.veteran_participant_id)
        expect(ri2.rating_issue_associated_at).to eq("2024-05-22 13:13:30.000000000 -0400".to_datetime)
      end
    end

    context "when there are associated VACOLS Issues with the RequestIssues" do
      it "should create RequestIssues as well as LegacyIssues" do
        hash = JSON.parse(payload)
        hash["request_issues"][0]["vacols_id"] = "DRCTEST"
        hash["request_issues"][0]["vacols_sequence_id"] = 1

        parser = Events::DecisionReviewCreated::DecisionReviewCreatedParser.new({}, hash)

        backfilled_issues = subject.process!(event: event, parser: parser, epe: epe,
                                             decision_review: higher_level_review)

        expect(backfilled_issues.count).to eq(1)
        expect(RequestIssue.count).to eq(1)
        expect(LegacyIssue.count).to eq(1)
        expect(EventRecord.count).to eq(2)
      end
    end

    context "when there are legacy opt-ins" do
      it "should create RequestIssues, LegacyIssues and LegacyIssueOptins" do
        hash = JSON.parse(payload)
        hash["request_issues"][0]["vacols_id"] = "DRCTEST"
        hash["request_issues"][0]["vacols_sequence_id"] = 1

        parser = Events::DecisionReviewCreated::DecisionReviewCreatedParser.new({}, hash)
        higher_level_review.update!(legacy_opt_in_approved: true)

        backfilled_issues = subject.process!({ event: event, parser: parser, epe: epe,
                                               decision_review: higher_level_review })

        expect(backfilled_issues.count).to eq(1)
        expect(RequestIssue.count).to eq(1)
        expect(LegacyIssue.count).to eq(1)
        expect(LegacyIssueOptin.count).to eq(1)
        expect(EventRecord.count).to eq(3)
      end
    end

    context "when an error occurs" do
      it "the error is caught and Caseflow::Error::DecisionReviewCreatedRequestIssuesError is raised" do
        parser = Events::DecisionReviewCreated::DecisionReviewCreatedParser.new({}, retrieve_payload)

        expect { described_class.process!(event: event, parser: parser, epe: nil, decision_review: nil) }
          .to raise_error(Caseflow::Error::DecisionReviewCreatedRequestIssuesError)
      end
    end

    context "when parser_issues.ri_reference_id is nil" do
      it "raises Caseflow::Error::DecisionReviewCreatedRequestIssuesError" do
        invalid_payload = retrieve_payload
        invalid_payload[:request_issues][0][:decision_review_issue_id] = nil

        parser = Events::DecisionReviewCreated::DecisionReviewCreatedParser.new({}, invalid_payload)

        expect do
          described_class.process!(event: event, parser: parser, epe: epe, decision_review: higher_level_review)
        end.to raise_error(Caseflow::Error::DecisionReviewCreatedRequestIssuesError, "reference_id cannot be null")
      end

      it "does not create any RequestIssues when ri_reference_id is nil" do
        invalid_payload = retrieve_payload
        invalid_payload[:request_issues][0][:decision_review_issue_id] = nil

        parser = Events::DecisionReviewCreated::DecisionReviewCreatedParser.new({}, invalid_payload)

        expect do
          described_class.process!(event: event, parser: parser, epe: epe, decision_review: higher_level_review)
        end.to raise_error(Caseflow::Error::DecisionReviewCreatedRequestIssuesError)

        # Ensure no RequestIssues or EventRecords are created
        expect(RequestIssue.count).to eq(0)
        expect(EventRecord.count).to eq(0)
      end
    end

    def retrieve_payload
      {
        "request_issues": [
          {
            "decision_review_issue_id": "1",
            "benefit_type": "pension",
            "contested_issue_description": "service connection for arthritis denied",
            "contention_reference_id": 4_542_785,
            "contested_rating_decision_reference_id": nil,
            "contested_rating_issue_profile_date": nil,
            "contested_rating_issue_reference_id": nil,
            "contested_decision_issue_id": nil,
            "decision_date": 20_240_314,
            "ineligible_due_to_id": nil,
            "ineligible_reason": nil,
            "is_unidentified": true,
            "unidentified_issue_text": nil,
            "nonrating_issue_category": "DIC",
            "nonrating_issue_description": nil,
            "untimely_exemption": nil,
            "untimely_exemption_notes": nil,
            "vacols_id": "DRCTEST",
            "vacols_sequence_id": nil,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": nil,
            "ramp_claim_id": nil,
            "rating_issue_associated_at": nil,
            "nonrating_issue_bgs_id": "12",
            "nonrating_issue_bgs_source": "Test Source"
          },
          {
            "decision_review_issue_id": "2",
            "benefit_type": "pension",
            "contested_issue_description": "PTSD",
            "contention_reference_id": 123_456,
            "contested_rating_decision_reference_id": "12",
            "contested_rating_issue_profile_date": nil,
            "contested_rating_issue_reference_id": nil,
            "contested_decision_issue_id": nil,
            "decision_date": 20_240_314,
            "ineligible_due_to_id": nil,
            "ineligible_reason": nil,
            "is_unidentified": false,
            "unidentified_issue_text": nil,
            "nonrating_issue_category": nil,
            "nonrating_issue_description": nil,
            "untimely_exemption": false,
            "untimely_exemption_notes": nil,
            "vacols_id": "DRCTEST",
            "vacols_sequence_id": nil,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": nil,
            "ramp_claim_id": nil,
            "rating_issue_associated_at": 1_716_398_010_000,
            "nonrating_issue_bgs_id": nil
          }
        ]
      }
    end
  end
end
