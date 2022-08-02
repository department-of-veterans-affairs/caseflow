# frozen_string_literal: true

class SplitAppealController < ApplicationController
  include FastJsonapi::ObjectSerializer

  def index
    respond_to do |format|
      format.html { render template: "/appeals/:appeal_id/split/" }
      console.log (format.html)
    end
  end
end
