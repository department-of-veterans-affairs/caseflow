# frozen_string_literal: true

class SearchQueryService::QueriedHearing < SimpleDelegator
  def initialize(attributes)
    @attributes = attributes

    super(hearing)
  end

  def judge
    @judge ||=
      if judge_attributes.present?
        User.new.tap do |judge|
          judge.assign_attributes judge_attributes
        end
      end
  end

  def hearing_views
    @hearing_views ||=
      if views_attributes.present?
        views_attributes.map do |view_attrs|
          HearingView.new.tap do |view|
            view.assign_attributes view_attrs
          end
        end
      else
        []
      end
  end

  def readable_request_type
    Hearing::HEARING_TYPES[hearing_day&.request_type&.to_sym]
  end

  def hearing_day
    @hearing_day ||=
      if hearing_day_attributes.present?
        HearingDay.new.tap do |hd|
          hd.assign_attributes hearing_day_attributes
        end
      end
  end

  def updated_by
    @updated_by ||=
      if updated_by_attributes.present?
        User.new.tap do |user|
          user.assign_attributes updated_by_attributes
        end
      end
  end

  def virtual?
    %w(pending active closed).include?(
      virtual_hearing&.status
    )
  end

  def scheduled_for
    updated_by_timezone = updated_by&.timezone || Time.zone.name
    scheduled_for_hearing_day(hearing_day, updated_by_timezone, regional_office_timezone)
  end

  private

  attr_reader :attributes

  EXTRA_ATTRIBUTES = [
    :hearing_day,
    :updated_by,
    :views,
    :virtual_hearing,
    :judge
  ].freeze

  def regional_office_timezone
    RegionalOffice.find!(hearing_day.regional_office || "C").timezone
  end

  def virtual_hearing
    @virtual_hearing ||=
      if virtual_hearing_attributes.present?
        VirtualHearing.new.tap do |vh|
          vh.assign_attributes virtual_hearing_attributes
        end
      end
  end

  def hearing
    Hearing.new.tap do |hearing|
      hearing.assign_attributes hearing_attributes
    end
  end

  def hearing_attributes
    attributes.without(*EXTRA_ATTRIBUTES.map(&:to_s))
  end

  def hearing_day_attributes
    attributes["hearing_day"]
  end

  def updated_by_attributes
    attributes["updated_by"]
  end

  def views_attributes
    attributes["views"] || []
  end

  def virtual_hearing_attributes
    attributes["virtual_hearing"]
  end

  def judge_attributes
    attributes["judge"]
  end
end
