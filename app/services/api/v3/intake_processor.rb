# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeProcessor
  attr_reader :errors, :intake

  def initialize(params, user, form_type)
    @params = Api::V3::DecisionReview::IntakeParams.new(params)
    @errors = @params.errors # initialize the errors array with any errors caught by IntakeParams
    build_intake(user, form_type)
  end

  def errors?
    errors.any?
  end

  # this method performs all of the intake steps which write to DBs.
  # this method fails by exception. some exceptions will have an error_code method
  def run!
    ActiveRecord::Base.transaction do
      start!
      review!
      complete!
    end
  end

  private

  def build_intake(user, form_type)
    @intake = Intake.build(user: user, veteran_file_number: @params.veteran_file_number, form_type: form_type)
    @errors << Api::V3::DecisionReview::IntakeError.new(intake) if intake.error_code
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
