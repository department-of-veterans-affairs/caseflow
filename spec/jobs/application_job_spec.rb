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
      allow()
      expect(true).to be false
    end
  end
end
