# frozen_string_literal: true

class WorkQueue::UserSerializer
  include FastJsonapi::ObjectSerializer
  attribute :css_id
  attribute :full_name

  attribute :is_admin do |object, params|
    params[:check_if_admin] ? params[:organization].user_is_admin?(object) : nil
  end
end
