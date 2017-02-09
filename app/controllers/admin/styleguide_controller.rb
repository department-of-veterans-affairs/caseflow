class Admin::StyleguideController < ApplicationController
  include ActionView::Helpers::CaptureHelper
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Context
  before_action :verify_system_admin
  layout "styleguide"

  def code_block(&block)
    result = capture(&block)
    raw(result)
  end

  helper_method :code_block
end
