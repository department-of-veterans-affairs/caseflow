# frozen_string_literal: true

require "json"

describe Events::DecisionReviewCreated::CreateRequestIssues do
  let!(:event) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
  let!(:epe) { create(:end_product_establishment) }

  describe "#process!" do
    subject { described_class }

    context "when receiving an Event with request_issues" do
      it "should create CF RequestIssues and backfill records" do
        parser = Events::DecisionReviewCreated::DecisionReviewCreatedParser.new({}, get_payload)

        backfilled_issues = subject.process!(event, parser, epe)

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
        expect(ri1.end_product_establishment_id).to eq(epe.id)

        expect(ri2.benefit_type).to eq("pension")
        expect(ri2.contested_issue_description).to eq("PTSD")
        expect(ri2.contention_reference_id).to eq(123_456)
        expect(ri2.nonrating_issue_category).to eq(nil)
        expect(ri2.decision_date).to eq(parser.logical_date_converter(20_240_314))
        expect(ri2.nonrating_issue_bgs_id).to eq(nil)
        expect(ri2.end_product_establishment_id).to eq(epe.id)
      end
    end

    def get_payload
      data = {
        "request_issues": [
          {
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
            "vacols_id": nil,
            "vacols_sequence_id": nil,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": nil,
            "ramp_claim_id": nil,
            "rating_issue_associated_at": nil,
            "nonrating_issue_bgs_id": "12"
          },
          {
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
            "vacols_id": nil,
            "vacols_sequence_id": nil,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": nil,
            "ramp_claim_id": nil,
            "rating_issue_associated_at": nil,
            "nonrating_issue_bgs_id": nil
          }
        ]
      }
      JSON.generate(data)
    end
  end
end
