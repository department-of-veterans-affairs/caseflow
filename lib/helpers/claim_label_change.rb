# frozen_string_literal: true

module WarRoom
  class CodeGroup
    attr_reader :original_code, :new_code
    attr_accessor :epe

    def initialize(epe, original_code, new_code)
      @epe = epe
      @original_code = original_code
      @new_code = new_code
    end
  end

  class ClaimLabelChange
    def initialize(epe, original_code, new_code)
      @codes = CodeGroup.new(epe, original_code, new_code)
    end

    def update_vbms
      # An End Product Update is created with the desired changes.
      ep_update = EndProductUpdate.create!(
        end_product_establishment: @codes.epe,
        original_decision_review: @codes.epe.source,
        original_code: @codes.original_code,
        new_code: @codes.new_code,
        user: User.system_user
      )
      # Perform the End Product Update. Note the return message.
      ep_update.perform!

      # print the End Product Update to confirm the results.
      pp ep_update
    end

    def claim_checker
      # The End products must be of the same type. (030, 040, 070)
      if same_claim_type == false
        puts("This is a different End Product, cannot claim label change. Aborting...")
        fail Interrupt
      end

      # Check that the new claim code is valid
      if claim_code_check == false
        puts("Invalid new claim label code. Aborting...")
        fail Interrupt
      end

      # Check that the old claim code is valid for record
      if claim_code_check == false
        puts("Invalid orginal claim label code. Aborting...")
        fail Interrupt
      end
    end

    def claim_label_updater(reference_id)
      claim_checker

      # set the user
      RequestStore[:current_user] = WarRoom.user

      # find the End Product by claim ID
      @codes.epe = EndProductEstablishment.find_by(reference_id: reference_id)

      # validate EPE exists.
      if @codes.epe.nil?
        puts("Unable to find EPE for that reference id. Aborting...")
        fail Interrupt
      end

      # check the EPE by printing to console.
      pp @codes.epe

      # check caseflow
      if @codes.epe.code != @codes.new_code
        update_caseflow(@codes.epe)
      end

      # check VBMS
      bgs = BGSService.new.client.claims
      # fetch Claim details from VBMS by Claim_ID
      claim_detail = bgs.find_claim_detail_by_id(@codes.epe.reference_id)
      # retrieve specific record
      record = claim_detail[:benefit_claim_record]
      # retrieve Claim code from record
      claim_label_check = record[:claim_type_code]

      # If the claim label in VBMS does not match the new code, Update it
      if claim_label_check != @codes.new_code
        update_vbms
      end
    end

    private

    def claim_code_check(code)
      # Declare hash
      codes_hash = []

      # File open and process.
      File.open("lib/helpers/END_PRODUCT_CODES.json") do |file|
        codes_hash = JSON.parse(file.read)
      end

      # if claim code is in hash return true, else false.
      codes_hash.key?(code)
    end

    def same_claim_type
      # Checks the sameness of the first two chacters as a substing
      @codes.old_code[0, 2] == @codes.new_code[0, 2]
    end

    def update_caseflow
      # Update the End Product in Caseflow.
      @codes.epe.update(code: @codes.new_code)

      # Save the changes to the End Product.
      @codes.epe.save
    end
  end
end
