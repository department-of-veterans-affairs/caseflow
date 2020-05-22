# frozen_string_literal: true

class RouteDocsController < ApplicationController
  def index
    @routes = Rails.application.routes.routes.map(&method(:make_doc)).compact.sort_by { |rt| rt[:path] }
  end

  private

  def make_doc(route)
    return nil unless route.defaults.key?(:controller) && route.defaults.key?(:action)

    {
      verb: route.verb,
      path: route.path.spec.to_s,
      controller: route.defaults[:controller],
      action: route.defaults[:action],
      schema: get_schema(route)
    }
  end

  def get_schema(route)
    klass = ActionDispatch::Request.new({}).controller_class_for(route.defaults[:controller])
    return unless klass.respond_to?(:validation_schemas)

    klass.validation_schemas[route.defaults[:action].to_sym]
  rescue NameError
    nil
  end
end
