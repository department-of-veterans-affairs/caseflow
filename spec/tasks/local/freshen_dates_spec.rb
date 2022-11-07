# frozen_string_literal: true

require "rails_helper"
require "rake"

describe "fresh_dates" do
  before :all do
    load File.expand_path("../../../lib/tasks/local/freshen_dates.rake", __dir__)
    Rake::Task.define_task(:environment)
  end

  subject { Rake::Task["db:freshen_dates"].execute }

  context "whenever the Rails.env is development" do
    before { allow(Rails.env).to receive(:development?).and_return(true) }

    context "invalid input is provided as the days count to increment by" do
      before { ENV["DAYS"] = "Something that isn't a number" }

      it "will throw an exception" do
        expect { subject }.to raise_exception(
          ArgumentError,
          "Please specify a valid number of days."
        )
      end
    end
  end

  context "whenever the Rails.env is not development" do
    before { allow(Rails.env).to receive(:development?).and_return(false) }

    it "will abort script" do
      expect { subject }.to raise_exception(
        RuntimeError,
        "This task can only be run in a development instance of Caseflow"
      )
    end
  end
end
