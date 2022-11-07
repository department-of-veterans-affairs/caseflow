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

    shared_examples "task dates are freshened" do
      it "the dates are incremented as expected" do
        assigned_ats_before_freshening = tasks.pluck(:assigned_at)

        subject

        updated_assigned_at_dates = tasks.each(&:reload).pluck(:assigned_at).map(&:to_date)

        original_dates_plus_expected_increase = assigned_ats_before_freshening.map do |assigned_at|
          (assigned_at + days_increased.days).to_date
        end

        expect(
          updated_assigned_at_dates - original_dates_plus_expected_increase
        ).to match_array []
      end
    end

    context "valid input is provided" do
      let!(:tasks) { create_list(:task, 10) }

      context "no explicit input is given" do
        let!(:days_increased) { 60 }

        it_behaves_like "task dates are freshened"
      end

      context "explicit number of days is given" do
        let!(:days_increased) { 45 }

        before { ENV["DAYS"] = "45" }

        it_behaves_like "task dates are freshened"
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
