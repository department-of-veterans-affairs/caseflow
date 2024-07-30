# frozen_string_literal: true

# abstract class intended to define an interface for the DataIntegrityChecksJob to consume.
# subclasses will be called by the job.

class DataIntegrityChecker
  attr_reader :buffer

  def initialize
    @report = []
    @buffer = []
  end

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

  def add_to_buffer(thing)
    @buffer << thing
  end
end
