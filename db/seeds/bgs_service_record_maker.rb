# frozen_string_literal: true

module Seeds
  class BgsServiceRecordMaker < Base
    # :reek:UtilityFunction
    def seed!
      # run the BGSServiceMaker file located in lib/fakes
      # seed data comes from a CSV file called 'bgs_setup.csv' located at docker-bin/oracle_libs/bgs_setup.csv
      Fakes::BGSServiceRecordMaker.new.call
    end
  end
end
