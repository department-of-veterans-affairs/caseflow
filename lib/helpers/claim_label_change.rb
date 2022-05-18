module WarRoom
    class ClaimLabelChange
        def UpdateVBMS(epe, original_code, new_code)
            #An End Product Update is created with the desired changes.
            ep_update = EndProductUpdate.create!(
                    end_product_establishment: epe,
                    original_decision_review: epe.source,
                    original_code: original_code,
                    new_code: new_code,
                    user: User.system_user
                    )	

            #Perform the End Product Update. Note the return message. 
            ep_update.perform!

            #print the End Product Update to confirm the results. 
            pp ep_update          
        
        end

        def claim_code_check(code)
            #load json file of Claim codes
            file = File.open("END_PRODUCT_CODES.json")

            #Parse json to ruby hash
            codes_hash = JSON.parse(file)

            #if claim code is in hash return true, else false.
            return codes_hash[:code] ? true : false
        end

        def same_claim_type?(old_code, new_code)
            if(old_code[0,2] == new_code[0,2])
                return true
            else
                return false
            end
        end


        def UpdateCaseflow(epe, new_code)
            #Update the End Product in Caseflow. 
            epe.update(code: new_code)

            #Save the changes to the End Product. 
            epe.save
        end
       
        def ClaimLabelUpdater(reference_id, original_code, new_code)

            if (same_claim_type?(original_code, new_code) == false)
                puts("This is a different End Product, cannot claim label change. Aborting...")
                fail Interrupt
            end

            if (claim_code_check(new_code) == false)
                puts("Invalid claim label code. Aborting...")
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
                UpdateCaseflow(epe, new_code)
             end

             #check VBMS
             #todo: Test this 
            bgs = BGSService.new.client.claims
            claim_detail = bgs.find_claim_detail_by_id(epe.reference_id)
            record = claim_detail[:benefit_claim_record]
            claim_label_check = record[:claim_type_code]
        
            if(claim_label_check != new_code)
                UpdateVBMS(epe, original_code, new_code)
            end

        end

        


    

