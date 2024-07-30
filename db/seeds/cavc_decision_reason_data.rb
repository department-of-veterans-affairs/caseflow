# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
module Seeds
  class CavcDecisionReasonData < Base
    def seed!
      create_cavc_decision_reasons
    end

    private

    def create_cavc_decision_reasons
      # decision reason parents
      CavcDecisionReason.create(decision_reason: "Duty to notify", order: 1)
      parent_1 = CavcDecisionReason.create(decision_reason: "Duty to assist", order: 2)
      CavcDecisionReason.create(decision_reason: "Comply with prior CAVC remand", order: 3)
      CavcDecisionReason.create(decision_reason: "Hearing related", order: 4)
      CavcDecisionReason.create(decision_reason: "Provide representative an opportunity to submit argument", order: 5)
      CavcDecisionReason.create(decision_reason: "Other due process protection",
                                basis_for_selection_category: :other_due_process_protection, order: 6)
      CavcDecisionReason.create(decision_reason: "Adjudicate issue properly before the Board", order: 7)
      CavcDecisionReason.create(decision_reason: "Issue inextricably intertwined with another issue", order: 8)
      parent_2 = CavcDecisionReason.create(decision_reason: "Provide VA examination", order: 9)
      parent_3 = CavcDecisionReason.create(decision_reason: "Obtain VA opinion", order: 10)
      CavcDecisionReason.create(decision_reason: "Other statutory or regulatory duty", order: 11)
      parent_4 = CavcDecisionReason.create(decision_reason: "Consider statute/regulation/diagnostic code/caselaw",
                                           order: 12)
      CavcDecisionReason.create(decision_reason: "Consider lay evidence", order: 13)
      CavcDecisionReason.create(decision_reason: "Consider service/private/VA medical advice", order: 14)
      CavcDecisionReason.create(decision_reason: "Consider theory of entitlement/contentions", order: 15)
      parent_5 = CavcDecisionReason.create(
        decision_reason: "Misapplication of statute/regulation/diagnostic code/caselaw",
        order: 16
      )
      CavcDecisionReason.create(decision_reason: "Improper medical conclusion [Colvin violation]", order: 17)
      parent_6 = CavcDecisionReason.create(decision_reason: "AMA specific remand", order: 18)

      # decision reason children
      # Parent: Duty to assist
      CavcDecisionReason.create(decision_reason: "Treatment records", parent_decision_reason_id: parent_1.id, order: 1)
      CavcDecisionReason.create(decision_reason: "Service records (medical/personnel)",
                                parent_decision_reason_id: parent_1.id, order: 2)

      # Parent: Provide VA examination
      CavcDecisionReason.create(decision_reason: "Prior examination inadequate", parent_decision_reason_id: parent_2.id,
                                basis_for_selection_category: :prior_examination_inadequate, order: 1)
      CavcDecisionReason.create(decision_reason: "No VA examination provided", parent_decision_reason_id: parent_2.id,
                                order: 2)

      # Parent: Obtain VA opinion
      CavcDecisionReason.create(decision_reason: "Prior opinion inadequate", parent_decision_reason_id: parent_3.id,
                                basis_for_selection_category: :prior_opinion_inadequate, order: 1)
      CavcDecisionReason.create(decision_reason: "No VA opinion provided", parent_decision_reason_id: parent_3.id,
                                order: 2)

      # Parent: Consider statute/regluation/diagnostic code/caselaw
      CavcDecisionReason.create(decision_reason: "Statute", parent_decision_reason_id: parent_4.id,
                                basis_for_selection_category: :consider_statute, order: 1)
      CavcDecisionReason.create(decision_reason: "Regulation", parent_decision_reason_id: parent_4.id,
                                basis_for_selection_category: :consider_regulation, order: 2)
      CavcDecisionReason.create(decision_reason: "Diagnostic code", parent_decision_reason_id: parent_4.id,
                                basis_for_selection_category: :consider_diagnostic_code, order: 3)
      CavcDecisionReason.create(decision_reason: "Caselaw", parent_decision_reason_id: parent_4.id,
                                basis_for_selection_category: :consider_caselaw, order: 4)

      # Parent: Misapplication of statute/regulation/diagnostic code/caselaw
      CavcDecisionReason.create(decision_reason: "Statute", parent_decision_reason_id: parent_5.id,
                                basis_for_selection_category: :misapplication_statute, order: 1)
      CavcDecisionReason.create(decision_reason: "Regulation", parent_decision_reason_id: parent_5.id,
                                basis_for_selection_category: :misapplication_regulation, order: 2)
      CavcDecisionReason.create(decision_reason: "Diagnostic code", parent_decision_reason_id: parent_5.id,
                                basis_for_selection_category: :misapplication_diagnostic_code, order: 3)
      CavcDecisionReason.create(decision_reason: "Caselaw", parent_decision_reason_id: parent_5.id,
                                basis_for_selection_category: :misapplication_caselaw, order: 4)

      # Parent: AMA specific remand
      CavcDecisionReason.create(decision_reason: "Improperly considered evidence not part of record on appeal",
                                parent_decision_reason_id: parent_6.id, order: 1)
      CavcDecisionReason.create(
        decision_reason: "Make a 20.104(c) determination/send a 20.104(c) letter before dismissal",
        parent_decision_reason_id: parent_6.id,
        order: 2
      )
      CavcDecisionReason.create(decision_reason: "Apply correct new and relevant evidence standard",
                                parent_decision_reason_id: parent_6.id, order: 3)
      CavcDecisionReason.create(decision_reason: "Address Docket Switch request",
                                parent_decision_reason_id: parent_6.id, order: 4)
      CavcDecisionReason.create(decision_reason: "Issuing a decision before 90-day window closed",
                                parent_decision_reason_id: parent_6.id, order: 5)
      CavcDecisionReason.create(decision_reason: "Failure to adopt favorable findings",
                                parent_decision_reason_id: parent_6.id, order: 6)
      CavcDecisionReason.create(decision_reason: "Other", parent_decision_reason_id: parent_6.id,
                                basis_for_selection_category: :ama_other, order: 7)
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
