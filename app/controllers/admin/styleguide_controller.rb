require "erb"
class Admin::StyleguideController < ApplicationController
  include ActionView::Helpers::CaptureHelper
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Context
  before_action :verify_system_admin
  layout "styleguide"

  def initialize_modal_erb
    @template = File.read(Rails.root.join("app/views/admin/styleguide/_modals.html.erb"))
  end

  helper_method :initialize_modal_erb

  def initialize_modal_react
    @template = File.read(Rails.root.join("app/views/admin/styleguide/_modals2.html.erb"))
  end

  helper_method :initialize_modal_react

  # Used for quick HTML only code snippets
  def code_block(&block)
    result = capture(&block)
    raw(result)
  end

  helper_method :code_block

  def code_sample(code)
    raw(code)
  end

  helper_method :code_sample
end
