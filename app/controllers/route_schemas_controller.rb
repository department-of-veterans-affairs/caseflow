# frozen_string_literal: true

class RouteSchemasController < ApplicationController
  def index
    respond_to do |format|
      format.text { render plain: text_lines.join("\n") }
      format.json { render json: route_docs }
    end
  end

  private

  def make_doc(route)
    return nil unless route.defaults.has_key?(:controller) && route.defaults.has_key?(:action)

    schema = schema_method_1(route) || schema_method_2(route) || schema_method_3(route)
    {
      verb: route.verb,
      path: route.path.spec.to_s,
      controller: route.defaults[:controller],
      action: route.defaults[:action],
      schema: (schema.present? ? DocCompiler.new.visit(schema.to_ast) : nil),
    }
  end

  # Approach 1: The schema for every #action is returned by #action_schema on the same
  # controller. This is the only approach with logic in the controller, which allows,
  # for example, different schemas for the same action based on a GET vs POST request.
  def schema_method_1(route)
    request = ActionDispatch::Request.new({})
    request.request_method = route.verb
    controller = request.controller_class_for(route.defaults[:controller]).new
    controller.set_request!(request)
    controller.try("#{route.defaults[:action]}_schema")
  rescue NameError
    nil
  end

  # Approach 2: Call #action on a companion class specified by the class const SCHEMAS.
  def schema_method_2(route)
    request = ActionDispatch::Request.new({})
    controller_class = request.controller_class_for(route.defaults[:controller])
    controller_class::SCHEMAS.try(route.defaults[:action])
  rescue NameError
    nil
  end

  # Approach 3: Similar to approach 2, but the companion class to ExampleController is
  # always ExampleSchemas. This is the most convention-over-configuration approach.
  def schema_method_3(route)
    schemas_class = "#{route.defaults[:controller].camelize}Schemas".constantize
    schemas_class.try(route.defaults[:action])
  rescue NameError
    nil
  end

  def route_docs
    Rails.application.routes.routes.map(&method(:make_doc)).compact
  end

  def text_lines
    lines = []
    route_docs.map do |doc|
      lines << "#{doc[:verb]} #{doc[:path]}"
      (doc[:schema] || []).each do |field|
        name = field.delete(:name)
        lines << "  #{name} #{field.inspect}"
      end
    end
    lines
  end
end
