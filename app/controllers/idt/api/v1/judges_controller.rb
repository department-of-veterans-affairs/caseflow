# frozen_string_literal: true

class Idt::Api::V1::JudgesController < Idt::Api::V1::BaseController
  before_action :verify_access

  def index
    render json: { data: Judge.list_all_with_name_and_id }
  end
end
