# frozen_string_literal: true

require "rails_helper"

class TestJob < ApplicationJob
  application_attr :fake

  def perform
    "Hello"
  end
end

describe "ApplicationJob" do
  context ".application_attr" do
    it "sets extra context" do
      allow(Raven).to receive(:extra_context)
      TestJob.perform_now
      expect(Raven).to have_received(:extra_context).with(application: "fake")
    end
  end
end
