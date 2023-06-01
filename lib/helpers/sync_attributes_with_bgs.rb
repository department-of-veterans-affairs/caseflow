# frozen_string_literal: true

module SyncAttributesWithBGS
  class VeteranCacheUpdater
    def self.run_by_file_number(file_number)
      veteran = Veteran.find_or_create_by_file_number(file_number, sync_name: true)

      if veteran.blank?
        puts "veteran was not found"
        fail Interrupt
      end

      puts "Veteran Name: #{veteran.first_name} #{veteran.middle_name} #{veteran.last_name}"
    end
  end

  class PersonCacheUpdater
    def self.run_by_participant_id(participant_id)
      person = Person.find_by(participant_id: participant_id)

      if person.blank?
        puts "person not found"
        fail Interrupt
      end
      if person.found?
        person.class.cached_bgs_attributes.each do |name_attr|
          fetched_attr = person.bgs_record[name_attr]
          if fetched_attr != person[name_attr]
            person[name_attr] = fetched_attr
          end
        end
        unless person.changes.any? && person.save
          puts "person was not updated"
        end
      else
        puts "bgs record not found"
        fail Interrupt
      end

      puts "Person Name: #{person.first_name} #{person.middle_name} #{person.last_name}"
    end
  end
end
