# frozen_string_literal: true

module HearingSerializerBase
  extend ActiveSupport::Concern

  class_methods do
    def default(object, **params)
      new(object, **params)
    end

    def quick(object, **params)
      params[:params] ||= {}
      params[:params][:quick] = true

      new(object, **params)
    end

    def worksheet(object, user, **params)
      params[:params] ||= {}
      params[:params][:worksheet] = true
      params[:params][:user] = user

      new(object, **params)
    end

    protected

    def for_full
      proc { |_record, params| !params[:quick] }
    end

    def for_worksheet
      proc { |_record, params| params[:worksheet] }
    end
  end
end
