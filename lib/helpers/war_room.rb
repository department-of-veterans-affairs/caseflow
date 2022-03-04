# frozen_string_literal: true

module WarRoom
  class Outcode
    def run(uuid_pass_in)
      # set current user
      RequestStore[:current_user] = OpenStruct.new(ip_address: "127.0.0.1", station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")
     
      uuid = uuid_pass_in
      # set appeal parameter
      appeal = Appeal.find_by_uuid(uuid)

      # view task tree
      appeal.treee

      # set decision document variable
      dd = appeal.decision_document

      FixFileNumberWizard.run(appeal: appeal)
      #need to do y or q
    end
  end
end
