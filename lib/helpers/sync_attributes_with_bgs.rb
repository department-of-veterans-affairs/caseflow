# frozen_string_literal: true

module SyncAttributesWithBGS
  class VeteranCacheUpdater
    def run_by_file_number(file_number)
      unless (veteran = Veteran.find_by_file_number_or_ssn(file_number, sync_name: true))
        puts "veteran was not found"
        return
      end

      puts "Veteran Name: #{veteran.first_name} #{veteran.middle_name} #{veteran.last_name}"
    end
  end

  class PersonCacheUpdater
    def run_by_participant_id(participant_id)
      unless (person = Person.find_by(participant_id: participant_id))
        puts "person was not found"
        return
      end

      return unless bgs_record?(person)

      begin
        person.update!(
          person.bgs_record.select { |attr_name, _value| Person::CACHED_BGS_ATTRIBUTES.include?(attr_name) }
        )
      rescue ActiveModel::ValidationError => error
        puts "#{error.message}\n\nthere was an error. person not updated."
        return
      end

      unless person.previous_changes.any?
        puts "person was not updated"
        return
      end
      puts "Person Name: #{person.first_name} #{person.middle_name} #{person.last_name}"
    end

    def bgs_record?(person)
      begin
        if person.found?
          true
        else
          puts "person bgs record not found"
          false
        end
      rescue StandardError => error
        puts "#{error.message}\n\nthere was bgs error. person not updated."
        false
      end
    end
  end
end
