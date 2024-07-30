# frozen_string_literal: true

module WarRoom
    class ClaimLabelChange
        def update_vbms(epe, original_code, new_code)
            # An End Product Update is created with the desired changes.
            ep_update = EndProductUpdate.create!(
                    end_product_establishment: epe,
                    original_decision_review: epe.source,
                    original_code: original_code,
                    new_code: new_code,
                    user: User.system_user
                    )	

            # Perform the End Product Update. Note the return message. 
            ep_update.perform!

            # print the End Product Update to confirm the results. 
            pp ep_update          
        
        end

        def claim_code_check(code)
            # Declare hash
            codes_hash =[]

            #File open and process. 
            File.open('lib/helpers/END_PRODUCT_CODES.json') do |f|
                codes_hash = JSON.parse(f.read)
            end

            #if claim code is in hash return true, else false.
            return codes_hash.has_key?(code)
        end

        def same_claim_type(old_code, new_code)
            # Checks the sameness of the first two chacters as a substing
            if(old_code[0,2] == new_code[0,2])
                return true
            else
                return false
            end
        end


        def update_caseflow(epe, new_code)
            # Update the End Product in Caseflow. 
            epe.update(code: new_code)

            # Save the changes to the End Product. 
            epe.save
        end
       
        def claim_label_updater(reference_id, original_code, new_code)

             #The End products must be of the same type. (030, 040, 070)
            if (same_claim_type(original_code, new_code) == false)
                puts("This is a different End Product, cannot claim label change. Aborting...")
                fail Interrupt
            end

            #Check that the new claim code is valid
             if (claim_code_check(new_code) == false)
                puts("Invalid new claim label code. Aborting...")
                fail Interrupt
             end

             #Check that the old claim code is valid for record
            if (claim_code_check(original_code) == false)
                puts("Invalid orginal claim label code. Aborting...")
                fail Interrupt
            end

             #set the user
             RequestStore[:current_user] = WarRoom.user

             #find the End Product by claim ID
             epe = EndProductEstablishment.find_by(reference_id: reference_id)
 
             #validate EPE exists. 
             if epe.nil?
                 puts("Unable to find EPE for that reference id. Aborting...")
                 fail Interrupt
             end
 
             #check the EPE by printing to console. 
             pp epe

             #check caseflow
             if(epe.code != new_code)
             update_caseflow(epe, new_code)
             end

            #check VBMS 
            bgs = BGSService.new.client.claims
            #fetch Claim details from VBMS by Claim_ID
            claim_detail = bgs.find_claim_detail_by_id(epe.reference_id)
            #retrieve specific record
            record = claim_detail[:benefit_claim_record]
            #retrieve Claim code from record
            claim_label_check = record[:claim_type_code]

            #If the claim label in VBMS does not match the new code, Update it
            if(claim_label_check != new_code)
                update_vbms(epe, original_code, new_code)
            end

        end
    end
end
