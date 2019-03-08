# frozen_string_literal: true

require "rails_helper"
require "rake"

describe "task rake tasks" do
  before :all do
    Rake.application = Rake::Application.new
    Rake.application.rake_require "tasks/tasks"
    Rake::Task.define_task :environment
  end

  describe "tasks:change_type" do
    let(:from_task) { ScheduleHearingTask }
    let(:from_task_name) { from_task.name }
    let(:to_task) { DispositionTask }
    let(:to_task_name) { to_task.name }

    subject do
      Rake::Task["tasks:change_type"].reenable
      Rake::Task["tasks:change_type"].invoke(*args)
    end

    context "there are tasks to change" do
      let(:task_count) { 10 }
      let(:subset_count) { 6 }
      let!(:hold_hearing_tasks) { FactoryBot.create_list(:schedule_hearing_task, task_count) }

      context "no dry run variable is passed" do
        let(:args) { [from_task_name, to_task_name] }

        it "only describes what changes will be made" do
          count = from_task.count
          ids = from_task.all.map(&:id)
          expected_output = <<~OUTPUT
            *** DRY RUN
            *** pass 'false' as the third argument to execute
            Would change #{count} #{from_task_name}s with ids #{ids.join(', ')} into #{to_task_name}s
            Would revert with: bundle exec rake tasks:change_type[#{to_task_name},#{from_task_name},#{ids.join(',')}]
          OUTPUT
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect { subject }.to output(expected_output).to_stdout
          expect(from_task.count).to eq task_count
          expect(from_task.all.map(&:id)).to eq ids
          expect(to_task.any?).to be_falsey
        end
      end

      context "dry run is set to false" do
        let(:args) { [from_task_name, to_task_name, "false"] }

        it "makes the requested changes" do
          count = from_task.count
          ids = from_task.all.map(&:id)
          expected_output = <<~OUTPUT
            Changing #{count} #{from_task_name}s with ids #{ids.join(', ')} into #{to_task_name}s
            Revert with: bundle exec rake tasks:change_type[#{to_task_name},#{from_task_name},#{ids.join(',')}]
          OUTPUT
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect(Rails.logger).to receive(:info).with(
            "Changing #{task_count} #{from_task_name}s with ids #{ids.join(', ')} into #{to_task_name}s"
          )
          expect { subject }.to output(expected_output).to_stdout
          expect(to_task.count).to eq task_count
          expect(to_task.all.map(&:id)).to eq ids
          expect(from_task.any?).to be_falsey
        end
      end

      context "id numbers are passed" do
        context "dry run is set to false" do
          let(:args) { [from_task_name, to_task_name, "false", *change_ids] }
          let(:change_ids) { [] }

          context "all the id numbers match existing tasks" do
            let(:change_ids) { hold_hearing_tasks.map(&:id)[0..subset_count - 1] }

            it "makes the requested changes" do
              count = change_ids.count
              expected_output = <<~OUTPUT
                Changing #{count} #{from_task_name}s with ids #{change_ids.join(', ')} into #{to_task_name}s
                Revert with: bundle exec rake tasks:change_type[#{to_task_name},#{from_task_name},#{change_ids.join(',')}]
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with(
                "Changing #{subset_count} #{from_task_name}s with ids #{change_ids.join(', ')} into #{to_task_name}s"
              )
              expect { subject }.to output(expected_output).to_stdout
              expect(to_task.count).to eq count
              expect(to_task.all.map(&:id)).to match_array(change_ids)
              expect(from_task.count).to eq task_count - subset_count
            end
          end

          context "some of the id numbers do not match existing tasks" do
            let!(:other_task) { FactoryBot.create(:ama_judge_decision_review_task) }
            let(:change_ids) { hold_hearing_tasks.map(&:id)[0..subset_count - 1] + [other_task.id] }

            it "raises an error" do
              message_pattern = /Couldn't find all #{from_task_name}s with 'id'/
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect { subject }.to raise_error(ActiveRecord::RecordNotFound).with_message(message_pattern)
            end
          end
        end

        context "no dry run variable is passed" do
          let(:args) { [from_task_name, to_task_name, *change_ids] }
          let(:change_ids) { hold_hearing_tasks.map(&:id)[0..subset_count - 1] }

          it "correctly describes what changes will be made" do
            count = change_ids.count
            joined = change_ids.join(",")
            expected_output = <<~OUTPUT
              *** DRY RUN
              *** pass 'false' as the third argument to execute
              Would change #{count} #{from_task_name}s with ids #{change_ids.join(', ')} into #{to_task_name}s
              Would revert with: bundle exec rake tasks:change_type[#{to_task_name},#{from_task_name},#{joined}]
            OUTPUT
            expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
            expect { subject }.to output(expected_output).to_stdout
            expect(from_task.count).to eq task_count
            expect(to_task.any?).to be_falsey
          end
        end
      end
    end

    context "there are no tasks to change" do
      let(:hold_hearing_tasks) { [] }
      let(:args) { [from_task_name, to_task_name, "false"] }

      it "tells the caller that there are no tasks to change" do
        expected_output = "There aren't any #{from_task_name}s available to change."
        expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
        expect { subject }.to raise_error(NoTasksToChange).with_message(expected_output)
      end
    end

    context "a non task class is passed" do
      let(:from_task) { JudgeTeam }
      let(:args) { [from_task_name, to_task_name, false] }

      it "warns about passing a class that's not a task" do
        expected_output = "#{from_task_name} is not a valid Task type!"
        expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
        expect { subject }.to raise_error(InvalidTaskType).with_message(expected_output)
      end
    end
  end
end
