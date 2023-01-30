# frozen_string_literal: true

# abstract base class for all Seed:: classes.
# inherit from this class for common util methods that (currently)
# wrap around FactoryBot

module Seeds
  class Base
    private

    def create(*args)
      FactoryBot.create(*args)
    end

    def build(*args)
      FactoryBot.build(*args)
    end

    def create_list(*args)
      FactoryBot.create_list(*args)
    end

    def initial_id_values(initial_file_number = 400_000_000 , initial_participant_id = 800_000_000)
      @file_number ||= initial_file_number
      @participant_id ||= initial_participant_id
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1)) ||
            VACOLS::Correspondent.find_by(ssn: format("%<n>09d", n: @file_number + 1))
        @file_number += 2000
        @participant_id += 2000
      end
    end

    def create_veteran(options = {})
      @file_number += 1
      @participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @file_number),
        participant_id: format("%<n>09d", n: @participant_id)
      }
      create(:veteran, params.merge(options))
    end
  end
end
