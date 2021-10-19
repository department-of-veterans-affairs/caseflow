# frozen_string_literal: true

require_relative "check_task_tree"

module ProductionConsoleMethods
  # Run this before and after modifying a task tree
  def check_task_tree(appeal, verbose: true)
    CheckTaskTree.call(appeal, verbose: verbose)
  end

  # Export an appeal for testing locally
  # https://github.com/department-of-veterans-affairs/caseflow/wiki/Exporting-and-Importing-Appeals
  # See examples in spec/fixes/
  def export_appeal(appeal, filename: "/tmp/appeal-#{appeal.id}.json", purpose: 'to diagnose appeal', verbosity: 5)
    sje = SanitizedJsonExporter.new(appeal, verbosity: verbosity)

    # Save to a file that is accessible by a non-root user like /tmp
    sje.save(filename, purpose: purpose)

    # Print instance ID so you can scp file locally
    instance_id = `curl http://169.254.169.254/latest/meta-data/instance-id`
    puts "Run this on your machine: scp #{instance_id}:#{filename} spec/records/"

    sje
  end
end
