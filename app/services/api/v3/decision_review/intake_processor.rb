# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeProcessor
  attr_reader :errors, :intake

  def initialize(params:, user:, form_type:, params_class:)
    @errors = []
    @params = params_class.new(params)
    @errors += @params.intake_errors
    @intake = errors? ? nil : build_intake(user, form_type)
    add_intake_error_if_intake_error_code
  rescue StandardError => error
    @errors << Api::V3::DecisionReview::IntakeError.new(error)
  end

  def errors?
    !errors.empty?
  end

  def run!
    return self if errors?

    ActiveRecord::Base.transaction do
      start!
      review!
      complete!
    end

    add_intake_error_if_intake_error_code
    intake.detail.reload
    self
  end

  def uuid
    intake&.detail&.uuid
  end

  private

  def build_intake(user, form_type)
    Intake.build(user: user, veteran_file_number: @params.veteran.file_number, form_type: form_type)
  end

  def add_intake_error_if_intake_error_code
    @errors << Api::V3::DecisionReview::IntakeError.new(intake) if intake.try(:error_code)
  end

  # both intake.start! and intake.review! can signal a failure by either
  # throwing an exception OR returning a falsey value. consequently, false
  # returns are turned into execptions (with error codes) to rollback the
  # transaction
  def start!
    fail(Api::V3::DecisionReview::StartError, intake) unless intake.start!
  end

  def review!
    fail(Api::V3::DecisionReview::ReviewError, intake) unless intake.review!(@params.review_params)
  end

  def complete!
    intake.complete!(@params.complete_params)
  end
end
