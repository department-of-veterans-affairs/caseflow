class HelpController < ApplicationController
  skip_before_action :verify_authentication

  def logo_name
    "Dispatch"
 end

  def logo_path
    "establish_claims_path"
  end
end
