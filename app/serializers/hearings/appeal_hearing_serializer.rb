# frozen_string_literal: true

class AppealHearingSerializer
  include FastJsonapi::ObjectSerializer

  attribute :date, &:scheduled_for
  attribute :disposition
  attribute :external_id
  attribute :held_by do |hearing, params|
    (!params[:user].vso_employee? && hearing.judge.present?) ? hearing.judge.full_name : nil
  end
  attribute :is_virtual, &:virtual?
  attribute :notes
  attribute :type, &:readable_request_type
  # this assumes only the assigned judge will view the hearing worksheet. otherwise,
  # we should check `hearing.hearing_views.map(&:user_id).include? judge.css_id`
  attribute :viewed_by_judge do |hearing|
    !hearing.hearing_views.empty?
  end
  attribute :created_at
end
