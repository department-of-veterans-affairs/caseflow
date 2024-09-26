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

  after do
    Timecop.return
  end

  let!(:vha_org) { VhaBusinessLine.singleton }
  let!(:vha_task) do
    hlr = create(:higher_level_review,
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
    hlr.tasks.first
  end

  let!(:events) do
    ClaimHistoryService.new(vha_org, task_id: vha_task.id).build_events
  end

  let(:modificationRequestDetailsObject) do
    {
      benefitType: "vha",
      requestType: nil,
      issueModificationRequestWithdrawalDate: nil,
      modificationRequestReason: nil,
      newDecisionDate: nil,
      newIssueDescription: nil,
      newIssueType: nil,
      previousDecisionDate: nil,
      previousIssueDescription: nil,
      previousIssueType: nil,
      previousModificationRequestReason: nil,
      previousWithdrawalDate: nil,
      removeOriginalIssue: nil,
      issueModificationRequestStatus: nil,
      requestor: nil,
      decider: nil,
      decidedAtDate: nil,
      decisionReason: nil
    }
  end

  let(:serialized_hash_array) do
    [
      {
        id: expected_uuid,
        type: :change_history_event,
        attributes: {
          claimType: "Higher-Level Review",
          readableEventType: "Claim created",
          claimantName: events[0].claimant_name,
          eventUser: "L. Roth",
          eventDate: events[0].event_date,
          eventType: :claim_creation,
          taskID: vha_task.id,
          details:
            {
              benefitType: "vha",
              decisionDate: nil,
              decisionDescription: nil,
              disposition: nil,
              dispositionDate: nil,
              issueDescription: nil,
              issueType: nil,
              withdrawalRequestDate: nil
            },
          modificationRequestDetails: modificationRequestDetailsObject
        }
      },
      {
        id: expected_uuid,
        type: :change_history_event,
        attributes: {
          claimType: "Higher-Level Review",
          readableEventType: "Added issue",
          claimantName: events[1].claimant_name,
          details:
          {
            benefitType: "vha",
            decisionDate: events[1].decision_date,
            decisionDescription: nil,
            disposition: nil,
            dispositionDate: nil,
            issueDescription: "Veterans Health Administration seeded HLR in progress",
            issueType: "Other",
            withdrawalRequestDate: nil
          },
          modificationRequestDetails: modificationRequestDetailsObject,
          eventDate: events[1].event_date,
          eventType: :added_issue,
          eventUser: "L. Roth",
          taskID: vha_task.id
        }
      },
      {
        id: expected_uuid,
        type: :change_history_event,
        attributes: {
          eventType: :in_progress,
          eventUser: "System",
          claimType: "Higher-Level Review",
          readableEventType: "Claim status - In progress",
          claimantName: events[2].claimant_name,
          details: {
            benefitType: "vha",
            issueType: nil,
            issueDescription: nil,
            decisionDate: nil,
            disposition: nil,
            decisionDescription: nil,
            dispositionDate: nil,
            withdrawalRequestDate: nil
          },
          modificationRequestDetails: modificationRequestDetailsObject,
          eventDate: events[2].event_date,
          taskID: vha_task.id
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
