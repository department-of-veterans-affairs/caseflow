module WarRoom
  class DuppEpClaimsSyncStatusUpdateCanClr

    def get_UUID
      gets.chomp.strip
    end

    def calc_problem_count
      scs = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'")
      hlr = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'")
      problem_scs = scs.select { |sc|
        sc.veteran.end_products.select { |ep|
          ep.claim_type_code.include?("040") && ["CAN", "CLR"].include?(ep.status_type_code) &&
          [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)
        }.empty?
      }
      problem_hlr = hlr.select { |hlr|
        hlr.veteran.end_products.select { |ep|
          ep.claim_type_code.include?("030") && ["CAN", "CLR"].include?(ep.status_type_code) &&
          [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)
        }.empty?
      }
      return problem_scs.count + problem_hlr.count
    end

    def get_problem_claim(uuid2)
      sc = SupplementalClaim.find_by(uuid: "#{uuid2}")
      hlr = HigherLevelReview.find_by(uuid: "#{uuid2}")

      if  sc.nil? && hlr.nil?
        [nil, "No SupplementalClaim or HigherLevelReview found with uuid: #{uuid2}\n"]
      elsif !sc.nil? && hlr.nil?
        puts "Putting data to be reviewed for SupplementalClaim ID #{sc.id}.\n"
        [sc, nil]
      elsif sc.nil? && !hlr.nil?
        puts "Putting data to be reviewed for HigherLevelReview ID #{hlr.id}.\n"
        [hlr, nil]
      else
        [nil, "Error: Multiple records found with the same UUID and establishment_error containing 'duplicateep'\n"]
      end
    end

    def get_yes_no_input
      gets.chomp.downcase
      while input != 'yes' && input != 'no'
        input = gets.chomp.downcase
      end
      input
    end

    def process_claim(epe)
      if epe.status_type_code == 'CAN'
        process_can_claim(epe)
      else
        process_clr_claim(epe)
      end
    end

    def process_clr_claim(epe)
      epe.update!(synced_status: 'CLR', last_synced_at: Time.zone.now)
      epe.send(:cancel!)
      epe.reload
      if calc_problem_count.zero?
        put 'No problem Supplemental Claims or Higher Level Reviews found after  CLR update. Exiting.\n'
      end
    end

    def process_can_claim(epe)
      epe.update!(synced_status: 'CAN', last_synced_at: Time.zone.now)
      epe.send(:cancel!)
      epe.reload
      if calc_problem_count.zero?
        put 'No problem Supplemental Claims or Higher Level Reviews found after CAN update. Exiting.\n'
      end
    end

    def run()
      RequestStore[:current_user] = OpenStruct.new(
        ip_address: '127.0.0.1',
        station_id: '283',
        css_id: 'CSFLOW',
        regional_office: 'DSUSER'
      )

      if calc_problem_count.zero?
        put 'No problem Supplemental Claims or Higher Level Reviews found. Exiting.\n'
        return false
      end

      duplicate_ep_problem_claim, err_msg = get_problem_claim(get_UUID)
      if !duplicate_ep_problem_claim
        put err_msg
        return 0
      end

      ActiveRecord::Base.transaction do
        epe = duplicate_ep_problem_claim.veteran.end_product_establishments&.first
        if epe.nil?
          put "Unable to find EPE for Problem Claim #{epe.id}."
          return 0
        end
        if epe.claim_type_code == '040' &&
          ['CAN', 'CLR'].include?(epe.status_type_code) &&
          [Date.today, 1.day.ago.to_date].include?(epe.last_action_date)

          input = get_yes_no_input
          if input == 'yes'
            process_claim
          else
            put "Unable to find EPE with CAN or CLR status and last action since a day ago for epe: #{epe.id}."
            return 0
          end
        end
      end
    end
  end
end
