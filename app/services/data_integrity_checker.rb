# frozen_string_literal: true

# abstract class intended to define an interface for the DataIntegrityChecksJob to consume.
# subclasses will be called by the job.

class DataIntegrityChecker
  def initialize
    @report = []
  end

  attr_writer :report

  def call
    # override your model/query here
  end

  def report?
    !@report.compact.empty?
  end

  def report
    @report.compact.join("\n")
  end

  def add_to_report(msg)
    @report << msg
  end

  def slack_channel
    "#appeals-app-alerts"
    # override this to specify a different channel
  end
end
