require "erb"
class StyleguideController < ApplicationController
  include ActionView::Helpers::CaptureHelper
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Context
  layout "styleguide"

  def initialize_modal_erb
    @template = File.read(Rails.root.join("app/views/styleguide/_modals.html.erb"))
  end

  helper_method :initialize_modal_erb

  def initialize_modal_react
    @template = File.read(Rails.root.join("app/views/styleguide/_modals2.html.erb"))
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
