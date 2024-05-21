# frozen_string_literal: true

class SearchQueryService::QueriedHearing < SimpleDelegator
  def initialize(attributes)
    @attributes = attributes
    manage_attributes

    super(hearing)
  end

  def hearing_day
    OpenStruct.new(hearing_day_attributes)
  end

  def updated_by
    OpenStruct.new(updated_by_attributes)
  end

  private

  attr_reader :attributes, :hearing_day_attributes, :updated_by_attributes

  def manage_attributes
    @hearing_day_attributes = attributes.delete("hearing_day")
    @updated_by_attributes = attributes.delete("updated_by")
  end

  def hearing
    Hearing.new.tap do |hearing|
      hearing.assign_attributes attributes
    end
  end
end
