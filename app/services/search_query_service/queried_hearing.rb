# frozen_string_literal: true

class SearchQueryService::QueriedHearing < SimpleDelegator
  def initialize(attributes)
    @attributes = attributes
    manage_attributes!
    super(hearing)
  end

  def judge
    @judge ||=
      if judge_attributes.present?
        User.new.tap do |j|
          j.assign_attributes judge_attributes
        end
      end
  end

  def hearing_views
    @hearing_views ||=
      views_attributes.map do |view_attrs|
        HearingView.new.tap do |v|
          v.assign_attributes view_attrs
        end
      end
  end

  def readable_request_type
    Hearing::HEARING_TYPES[hearing_day&.request_type&.to_sym]
  end

  def hearing_day
    @hearing_day ||= HearingDay.new.tap do |hd|
      hd.assign_attributes hearing_day_attributes
    end
  end

  def updated_by
    @updated_by ||= User.new.tap do |u|
      u.assign_attributes updated_by_attributes
    end
  end

  def virtual?
    %w(pending active closed).include?(
      virtual_hearing.status
    )
  end

  def scheduled_for
    scheduled_for_hearing_day(hearing_day, updated_by, regional_office_timezone)
  end

  private

  attr_reader(
    :attributes,
    :hearing_day_attributes,
    :updated_by_attributes,
    :views_attributes,
    :virtual_hearing_attributes,
    :judge_attributes
  )

  def regional_office_timezone
    RegionalOffice.find!(hearing_day.regional_office || "C").timezone
  end

  def virtual_hearing
    @virtual_hearing ||= VirtualHearing.new.tap do |vh|
      vh.assign_attributes virtual_hearing_attributes
    end
  end

  def hearing
    Hearing.new.tap do |hearing|
      hearing.assign_attributes attributes
    end
  end

  def manage_attributes!
    @hearing_day_attributes = attributes.delete("hearing_day")
    @updated_by_attributes = attributes.delete("updated_by")
    @views_attributes = attributes.delete("views") || []
    @virtual_hearing_attributes = attributes.delete("virtual_hearing")
    @judge_attributes = attributes.delete("judge")
  end
end
