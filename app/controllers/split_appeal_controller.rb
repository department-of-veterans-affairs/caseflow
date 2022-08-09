class SplitAppealController < ApplicationController

  #before_action :validate_split_access

  SPLIT_REQUIRED_PARAMS = [
    :source_appeal_id,
  ].freeze

  def source_appeal
    @source_appeal ||= Appeal.find_by_uuid(params[:source_appeal_id])
  end

  #def validate_split_access
    #unless COB.singleton.user_has_access?(current_user) || SSC.singleton.user_has_access?
      #msg = "Only COB & SSC users can split Appeals"
      #fail Caseflow::Error::ActionForbiddenError, message: msg
    #end
  #end

  #def split
  #end

end
