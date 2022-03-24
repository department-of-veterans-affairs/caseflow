module WarRoom
    class CreateClaimant

        def CreateVeteranClaimant(claim_id, claimant_participant_id, payee_code)
            #set current user
            RequestStore[:current_user] = WarRoom.user

            epe = EndProductEstablishment.find_by_reference_id(claim_id)

            vet = Veteran.find_by(participant_id: claimant_participant_id)

            if BGSService.new.fetch_file_number_by_ssn(vet.ssn).nil?
                fail Interrupt
            else
                puts("Claimant Found on BGS")
            end


            source = epe.source
            old_claimant = source.claimant
            new_claimant = VeteranClaimant.create!(decision_review: source, participant_id: claimant_participant_id, payee_code: payee_code)
            old_claimant.destroy!
            epe.reload
            epe.source.claimant


        end    

        def CreateDependentClaimant(claim_id, claimant_participant_id, payee_code)
            #set current user
            RequestStore[:current_user] = WarRoom.user

            epe = EndProductEstablishment.find_by_reference_id(claim_id)

            pers = Person.find_by(participant_id: claimant_participant_id)

            if BGSService.new.fetch_file_number_by_ssn(pers.ssn).nil?
                fail Interrupt
            else
                puts("Claimant Found on BGS")
            end

            source = epe.source
            old_claimant = source.claimant
            new_claimant = DependentClaimant.create!(decision_review: source, participant_id: claimant_participant_id, payee_code: payee_code)
            old_claimant.destroy!
            epe.reload
            epe.source.claimant
        end

    end
end