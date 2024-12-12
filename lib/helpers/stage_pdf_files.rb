# frozen_string_literal: true

module WarRoom
  class StagePDFFiles
    # @param file_number [String] File number of veteran that is to be staged
    def initialize(file_number)
      @file_number = file_number
      RequestStore[:current_user] = User.system_user
    end

    def run
      # TODO: implement
    end

    private

  end
end
