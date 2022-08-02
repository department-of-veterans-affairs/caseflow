# frozen_string_literal: true

class SplitAppealController < ApplicationController
  include FastJsonapi::ObjectSerializer
   attribute :source_appeal
   attribute :request_issues

  def index
    respond_to do |format|
      format.html { render template: "/appeals/:appeal_id/split/" }
    end
  end
end
