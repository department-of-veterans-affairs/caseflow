# frozen_string_literal: true

require_relative "check_task_tree"

module ProductionConsoleMethods
  # Prints a more readable version of PaperTrail versioning data
  # Usage: `pp _versions DistributionTask.last`
  # :reek:UtilityFunction
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

  # Counts the frequency of each distinct element in the array and
  # returns a hash representing a histogram for the given array
  # Example usage: count_freq(Task.pluck(:appeal_type))
  # :reek:UtilityFunction
  def count_freq(array)
    array.each_with_object(Hash.new(0)) { |obj, counts| counts[obj] += 1 }
  end
end
