# frozen_string_literal: true

require_relative "../../../app/services/claim_change_history/change_history_event_serializer.rb"
require_relative "../../../app/services/claim_change_history/claim_history_service.rb"
require_relative "../../../app/services/claim_change_history/claim_history_event.rb"

describe ChangeHistoryEventSerializer do
  let(:expected_uuid) { "709ab60d-3c5f-48d8-ac55-dc6b8f4f85bf" }
  before do
    Timecop.travel(5.days.ago)
    allow(SecureRandom).to receive(:uuid).and_return(expected_uuid)
  end

  let!(:vha_org) { VhaBusinessLine.singleton }
  let!(:vha_task) do
    create(:higher_level_review,
           :with_intake,
           :with_issue_type,
           :processed,
           :update_assigned_at,
           assigned_at: 2.days.ago,
           benefit_type: "vha",
           decision_date: 4.months.ago,
           claimant_type: :veteran_claimant,
           issue_type: "Other",
           description: "seeded HLR in progress",
           number_of_claimants: 1)
  end

  let!(:events) do
    ClaimHistoryService.new(vha_org, task_id: vha_task.id).build_events
  end

  let(:serialized_hash_array) do
    [
      {
        id: expected_uuid,
        type: :change_history_event,
        attributes: {
          claimType: "Higher-Level Review",
          claimantName: events[0].claimant_name,
          details:
          {
            benefitType: "vha",
            decisionDate: events[0].decision_date,
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
  end

  subject { described_class.new(events).serializable_hash[:data] }

  describe "#as_json" do
    it "renders json data" do
      expect(subject).to eq(serialized_hash_array)
    end
  end
end
