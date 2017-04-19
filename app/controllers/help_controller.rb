class HelpController < ApplicationController
  skip_before_action :verify_authentication
end
