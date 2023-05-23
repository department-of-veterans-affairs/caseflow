# frozen_string_literal: true

class VeteranNameUpdater
  def run_remediation_by_veteran_id(veteran_id)
    veteran = Veteran.find(veteran_id)

    if veteran.blank?
      puts "veteran not found"
      fail Interrupt
    end
    if veteran.bgs_record_found?
      ActiveRecord::Base.transaction do
        veteran.update_cached_attributes!
      end
    else
      puts "bgs record not found"
      fail Interrupt
    end

    puts "#{veteran.first_name} #{veteran.middle_name} #{veteran.last_name}"
  end
end
