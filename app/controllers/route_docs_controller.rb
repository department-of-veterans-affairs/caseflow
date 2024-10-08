# frozen_string_literal: true

class RouteDocsController < ApplicationController
  class DocumentedRoute
    SOURCE_URL_PREFIX = "https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/controllers/"

    attr_reader :rails_route

    delegate :defaults, :verb, to: :rails_route

    def initialize(rails_route)
      @rails_route = rails_route
    end

    def action
      defaults[:action]
    end

    def path
      rails_route.path.spec.to_s
    end

    def controller
      defaults[:controller]
    end

    def schema
      return unless controller_klass.respond_to?(:validation_schemas)

      controller_klass.validation_schemas[action.to_sym]
    end

    def source_url
      filepath, line = controller_klass.instance_method(action).source_location
      return unless filepath.include?("/app/controllers/")

      controller_path = filepath.rpartition("/app/controllers/").last
      "#{SOURCE_URL_PREFIX}#{controller_path}#L#{line}"
    rescue NameError
      nil
    end

    def valid?
      controller_klass && action.present?
    end

    def rails_internal?
      valid? && (path.start_with?("/rails") || controller.start_with?("rails"))
    end

    def controller_klass
      ActionDispatch::Request.new({}).controller_class_for(controller)
    rescue NameError
      nil
    end
  end

  def index
    all_routes = Rails.application.routes.routes.map(&method(:documented_route))
    @routes = all_routes.compact
      .filter { |route| route.schema.present? }
      .sort_by { |rt| [(rt.schema.present? ? 0 : 1), rt.path] }
  end

  private

  def documented_route(rails_route)
    route = DocumentedRoute.new(rails_route)
    return if !route.valid? || route.rails_internal?

    route
  end
end
