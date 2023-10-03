# frozen_string_literal: true

module Seeds
  class BGSServiceRecordMaker < Base
    def seed!
      # run the BGSServiceMaker file located in lib/fakes
      # seed data comes from a CSV file called 'bgs_setup.csv' located at local/vacols/bgs_setup.csv
      Fakes::BGSServiceRecordMaker.new.call
    end
  end
end
