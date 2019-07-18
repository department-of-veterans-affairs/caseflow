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

      context "perform migration" do
        let(:args) { ["false"] }

        it "makes changes and describes them" do
          description = []
          HearingDay.all.order(:id).each do |day|
            created_user = User.find_by(css_id: day.created_by)
            updated_user = User.find_by(css_id: day.updated_by)
            description << "Migrating created_by user #{created_user.id} (#{created_user.css_id}) for day #{day.id}"
            description << "Migrating updated_by user #{updated_user.id} (#{updated_user.css_id}) for day #{day.id}"
          end

          expected_output = <<~OUTPUT
            Migrating created and updated by information on #{day_count} HearingDays
            #{description.join("\n")}
          OUTPUT
          expect(Rails.logger).to receive(:info).with("Starting migration")
          description.each { |line| expect(Rails.logger).to receive(:info).with(line) }
          expect { subject }.to output(expected_output).to_stdout

          HearingDay.all.each do |day|
            expect(day.created_by_id).to eq User.find_by(css_id: day.created_by).id
            expect(day.updated_by_id).to eq User.find_by(css_id: day.updated_by).id
          end
        end

        context "a day has an updated_by css_id that doesn't correspond to an existing user" do
          let(:bad_css_id) { "A_CSS_ID_THAT_DOES_NOT_EXIST" }
          let(:target_day) { HearingDay.first }

          before do
            target_day.update!(updated_by: bad_css_id)
          end

          it "notes that the updated_by migration for that day didn't happen" do
            failed = "FAILED to migrate updated_by user for day #{target_day.id}"
            no_user = "no user with css_id #{bad_css_id}"

            expect { subject }.to output(/#{failed}; #{no_user}/).to_stdout
          end
        end

        context "a day already has its created_by_id set" do
          let(:target_day) { HearingDay.first }

          before do
            target_day.update!(created_by_id: User.find_by(css_id: target_day.created_by).id)
          end

          it "notes that the created_by migration for that day didn't happen" do
            failed = "FAILED to migrate created_by user for day #{target_day.id}"
            already_set = "created_by_id already set to #{target_day.created_by_id}"

            expect { subject }.to output(/#{failed}; #{already_set}/).to_stdout
          end
        end

        context "a day has a blank updated_by css_id" do
          let(:target_day) { HearingDay.first }

          before do
            target_day.update!(updated_by: "")
          end

          it "notes that the updated_by migration for that day didn't happen" do
            failed = "FAILED to migrate updated_by user for day #{target_day.id}; updated_by is blank"

            expect { subject }.to output(/#{failed}/).to_stdout
          end
        end
      end
    end
  end
end
