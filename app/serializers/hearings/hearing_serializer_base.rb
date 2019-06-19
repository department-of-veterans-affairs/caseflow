# frozen_string_literal: true

module HearingSerializerBase
  def default(object, **params)
    self.new(object, **params)
  end

  def quick(object, **params)
    params[:params] ||= {}
    params[:params][:quick] = true

    self.new(object, **params)
  end

  def worksheet(object, **params)
    params[:params] ||= {}
    params[:params][:worksheet] = true

    self.new(object, **params)
  end

  protected

  def for_full
    Proc.new { |_record, params| not params[:quick] }
  end

  def for_worksheet
    Proc.new { |_record, params| params[:worksheet] }
  end
end
