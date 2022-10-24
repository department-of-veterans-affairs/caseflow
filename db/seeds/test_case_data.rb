# frozen_string_literal: true

# This seed is intended to create specific test cases without changing the ID values for test data. Adding test
# cases to other seed files changes the order in which data is created and therefore the ID values of data,
# which can make regression testing difficult or change the ID values of known cases used in manual testing.

module Seeds
  class TestCaseData < Base
    def initialize
      initial_id_values
    end

    def seed!
      create_data_for_nod_update_testing
    end

    private

    def initial_id_values
      @file_number ||= 400_000_000
      @participant_id ||= 800_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1)) ||
            VACOLS::Correspondent.find_by(ssn: format("%<n>09d", n: @file_number + 1))
        @file_number += 2000
        @participant_id += 2000
      end
    end

    # this is commented out because it isn't needed right now, but if you need to create a caseflow veteran
    #  object use this method to increment ID numbers properly
    # def create_veteran(options = {})
    #   @file_number += 1
    #   @participant_id += 1
    #   params = {
    #     file_number: format("%<n>09d", n: @file_number),
    #     participant_id: format("%<n>09d", n: @participant_id)
    #   }
    #   create(:veteran, params.merge(options))
    # end

    # Create appeals in VACOLS to test veteran NOD updates
    def create_data_for_nod_update_testing
      5.times do
        # file_number is not used here, but incrementing to keep it synced with participant_id
        @file_number += 1
        @participant_id += 1
        create(
          :case,
          :type_original,
          :status_active,
          correspondent: create(
            :correspondent,
            stafkey: format("%<n>09d", n: @participant_id),
            ssn: format("%<n>09d", n: @participant_id),
            snamel: "TestUpdateNOD"
          )
        )
      end
    end
  end
end
