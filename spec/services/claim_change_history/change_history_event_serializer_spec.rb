# frozen_string_literal: true

require_relative "../../../app/services/claim_change_history/change_history_event_serializer.rb"
require_relative "../../../app/services/claim_change_history/claim_history_service.rb"
require_relative "../../../app/services/claim_change_history/claim_history_event.rb"

describe ChangeHistoryEventSerializer do
  let(:expected_uuid) { "709ab60d-3c5f-48d8-ac55-dc6b8f4f85bf" }
  before do
    Timecop.freeze(Time.utc(2024, 1, 30, 12, 0, 0))
    allow(SecureRandom).to receive(:uuid).and_return(expected_uuid)
  end

  let(:vha_org) { VhaBusinessLine.singleton }
  let(:vha_task) do
    create(:higher_level_review,
           :with_intake,
           :with_issue_type,
           :processed,
           :update_assigned_at,
           assigned_at: rand(1.year.ago..10.minutes.ago),
           benefit_type: "vha",
           decision_date: 4.months.ago,
           claimant_type: :veteran_claimant,
           issue_type: "Other",
           description: "seeded HLR in progress",
           number_of_claimants: 1)
  end

  let(:events) do
    ClaimHistoryService.new(vha_org, task_id: vha_task.id).build_events
  end

  subject { described_class.new(events) }

  describe "#as_json" do
    it "renders json data" do
      Timecop.travel(5.days.ago)
      serializable_hash = [
        {
          id: expected_uuid,
          type: :change_history_event,
          attributes: {
            claimType: "Higher-Level Review",
            claimantName: events[0].claimant_name,
            details:
            {
              benefitType: "vha",
              decisionDate: "2023-09-25",
              decisionDescription: nil,
              disposition: nil,
              issueDescription: "Veterans Health Administration seeded HLR in progress",
              issueType: "Other",
              withdrawalRequestDate: nil
            },
            eventDate: events[0].event_date,
            eventType: :added_issue,
            eventUser: "L. Roth",
            readableEventType: "Added Issue",
            taskID: 1
          }
        },
        {
          id: expected_uuid,
          type: :change_history_event,
          attributes: {
            claimType: "Higher-Level Review",
            claimantName: events[1].claimant_name,
            details:
            {
              benefitType: "vha",
              decisionDate: nil,
              decisionDescription: nil,
              disposition: nil,
              issueDescription: nil,
              issueType: nil,
              withdrawalRequestDate: nil
            },
            eventDate: events[1].event_date,
            eventType: :claim_creation,
            eventUser: "L. Roth",
            readableEventType: "Claim created",
            taskID: 1
          }
        }
      ]
      expect(subject.serializable_hash[:data]).to eq(serializable_hash)
    end
  end
end
