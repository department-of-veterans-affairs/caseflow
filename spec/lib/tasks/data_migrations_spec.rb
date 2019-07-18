# frozen_string_literal: true

require "rails_helper"
require "rake"

describe "data migration rake tasks" do
  before :all do
    Rake.application = Rake::Application.new
    Rake.application.rake_require "tasks/data_migrations"
    Rake::Task.define_task :environment
  end

  describe "data_migrations:migrate_hearing_day_created_and_updated_by" do
    let(:args) { [] }

    subject do
      Rake::Task["data_migrations:migrate_hearing_day_created_and_updated_by"].reenable
      Rake::Task["data_migrations:migrate_hearing_day_created_and_updated_by"].invoke(*args)
    end

    context "there are eligible hearing days" do
      let(:day_count) { 10 }
      let!(:hearing_days) { FactoryBot.create_list(:hearing_day, day_count) }

      before do
        HearingDay.all.each do |day|
          day.update!(created_by_id: nil, updated_by_id: nil)
        end
      end

      context "dry run" do
        it "only describes what changes will be made" do
          description = []
          HearingDay.all.order(:id).each do |day|
            created_user = User.find_by(css_id: day.created_by)
            updated_user = User.find_by(css_id: day.updated_by)
            description << "Would migrate created_by user #{created_user.id} (#{created_user.css_id}) for day #{day.id}"
            description << "Would migrate updated_by user #{updated_user.id} (#{updated_user.css_id}) for day #{day.id}"
          end

          expected_output = <<~OUTPUT
            *** DRY RUN
            *** pass 'false' as the first argument to execute
            Would migrate created and updated by information on #{day_count} HearingDays
            #{description.join("\n")}
          OUTPUT
          expect(Rails.logger).to receive(:info).with("Starting dry run")
          description.each { |line| expect(Rails.logger).to receive(:info).with(line) }
          expect { subject }.to output(expected_output).to_stdout
        end
      end
    end
  end
end
