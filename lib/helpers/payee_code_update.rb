# frozen_string_literal: true

# End Products in VBMS get established (through the processing of End Product Establishments in Caseflow)
# with a payee code. That code corresponds to the type of claimant on the claim (Veteran - 00, Spouse - 10, Child - 11).
# If a claim gets established with the incorrect payee code we do not have the ability to update the payee code in VBMS.
# Therefore we need to cancel the claim and re establish it with the correct payee code.

module WarRoom
  class PayeeCodeUpdate
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def run(reference_id, correct_payee_code)
      # set current user
      RequestStore[:current_user] =
        OpenStruct.new(ip_address: "127.0.0.1", station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")

      # Sets the variable End Product Establishment by the reference_id/Claim ID
      epe = EndProductEstablishment.find_by(reference_id: reference_id)

      if epe.nil?
        puts("Unable to find EPE for that reference id. Aborting...")
        fail Interrupt
      end

      # stores the source of the of the EPE if HLR, Supplemental or AMA/Legacy Appeal.
      # If decision document set to the appeal of the source.

      source = (epe.source_type != "DecisionDocument") ? epe.source : epe.source.appeal

      if source.nil?
        puts("Could not find a source for the orgional EPE. Aborting...")
        fail Interrupt
      end

      claimant = source.claimant

      # Re establish new end product with the correct payee code and origine EPE source information.
      epe2 = EndProductEstablishment.create(
        source_type: epe.source_type,
        source_id: epe.source_id,
        veteran_file_number: epe.veteran_file_number,
        claim_date: epe.claim_date,
        code: epe.code,
        station: epe.station,
        claimant_participant_id: claimant.present? ? claimant.participant_id : epe.claimant_participant_id,
        payee_code: correct_payee_code,
        doc_reference_id: epe.doc_reference_id,
        development_item_reference_id: epe.development_item_reference_id,
        benefit_type_code: epe.benefit_type_code,
        user_id: epe.user_id,
        limited_poa_code: epe.limited_poa_code,
        limited_poa_access: epe.limited_poa_access
      )

      if %w[030BGR 030BGRNR 030BGRPMC 030BGNRPMC].include?(epe.code)

        # If it's a Board Grant EPE (030BGR, 030BGRNR, 030BGRPMC, 030BGNRPMC)
        # We want to connect the newly created End Product Establishment to the
        # corresponding Board Grant Effectuation on the old EPE.
        epe.source.effectuations.update_all(end_product_establishment_id: epe2.id, contention_reference_id: nil)

      else
        # All other forms of EPEs, you will connect it to the Request Issues on the old EPE.
        epe.source.request_issues.update_all(end_product_establishment_id: epe2.id,
                                             contention_reference_id: nil, closed_status: nil, closed_at: nil)
      end

      # Establishes the new EP
      epe2.establish!
      # Cancels the orginal EP
      epe.send(:cancel!)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
