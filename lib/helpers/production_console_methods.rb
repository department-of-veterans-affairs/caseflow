# frozen_string_literal: true

require_relative "check_task_tree"

module ProductionConsoleMethods
  # https://stackoverflow.com/questions/4914913/how-do-i-include-a-module-into-another-module-refactor-aasm-code-and-custom-sta
  def self.included(klass)
    klass.class_eval do
      include FinderConsoleMethods
    end
  end

  # Prints a more readable version of PaperTrail versioning data
  # Usage: `pp _versions DistributionTask.last`
  def _versions(record)
    record.try(:versions)&.map do |version|
      {
        who: [User.find_by_id(version.whodunnit)].compact
          .map { |user| "#{user.css_id} (#{user.id}, #{user.full_name})" }.first,
        when: version.created_at,
        changeset: version.changeset
      }
    end
  end

  # Run this before and after modifying a task tree
  def check_task_tree(appeal, verbose: true)
    CheckTaskTree.call(appeal, verbose: verbose)
  end

  # Export an appeal for testing locally
  # https://github.com/department-of-veterans-affairs/caseflow/wiki/Exporting-and-Importing-Appeals
  # See examples in spec/fixes/
  # :reek:LongParameterList
  def export_appeal(appeal, filename: "/tmp/appeal-#{appeal.id}.json", purpose: "to diagnose appeal", verbosity: 5)
    sje = SanitizedJsonExporter.new(appeal, verbosity: verbosity)

    # Save to a file that is accessible by a non-root user like /tmp
    sje.save(filename, purpose: purpose)

    # Print instance ID so you can scp file locally
    instance_id = `curl http://169.254.169.254/latest/meta-data/instance-id`
    puts "Run this on your machine: scp #{instance_id}:#{filename} spec/records/"

    sje
  end
end
