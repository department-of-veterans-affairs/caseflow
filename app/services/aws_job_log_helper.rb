# frozen_string_literal: true

##
# Generates a pre-filtered AWS URL or AWS command to find logs for a Caseflow job

class AwsJobLogHelper
  # AWS Region in Production
  AWS_REGION = "us-gov-west-1"

  AWS_CONSOLE_BASE_URL = "console.amazonaws-us-gov.com"

  # AWS Cloudwatch Log group name for all Caseflow Jobs
  LOG_GROUP = "dsva-appeals-certification-prod/opt/caseflow-certification/src/log/caseflow-certification-sqs-worker.out"

  # Describes an ActiveJob.
  class JobInfo
    attr_reader :job_class, :job_id, :start_time, :end_time

    def initialize(job_class, job_id, start_time: (Time.zone.now - 1.day), end_time: Time.zone.now)
      @job_class = job_class    # REQUIRED: Class of the Job
      @job_id = job_id          # REQUIRED: Unique ActiveJob ID
      @start_time = start_time
      @end_time = end_time
    end

    def start_time_ms
      (start_time.to_f * 1000).to_i
    end

    def end_time_ms
      (end_time.to_f * 1000).to_i
    end

    # Builds a JobInfo instance from any ActiveJob instance.
    #
    # @param job [ActiveJob] Any instance of an ActiveJob.
    #
    # @return [JobInfo] A new JobInfo instance that describes the ActiveJob.
    def self.from_active_job(job, start_time: (Time.zone.now - 1.day), end_time: Time.zone.now)
      JobInfo.new(job.class, job.job_id, start_time, end_time)
    end

    # Builds the filter string to find the described job in AWS.
    #
    # @see https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax-examples.html
    #
    # @return [String] A query filter string to find the logging for the job in CloudWatch.
    def editor_string
      <<~EOF
        fields @timestamp, @message
        | parse "* * * ActiveJob/*/*/* *: *" as timestamp, pid, thread_id, job_class, queue_name, job_id, level, message
        | sort @timestamp desc
        | filter (job_class="#{job_class}" and job_id="#{job_id}")
      EOF
    end
  end

  # Renders a AWS CloudWatch URL to find logs for an ActiveJob.
  class UrlRenderer
    class << self
      def render(job_info)
        # The URL fragment contains info about the query for logs. See `UrlRenderer#build_query_detail`
        # for documentation about how this section of the URL is structured.
        query_detail = "#{escape('?queryDetail=')}#{lparen}#{build_query_detail(job_info)}#{rparen}".tr("%", "$")

        URI::HTTPS
          .build(
            host: AwsJobLogHelper::AWS_CONSOLE_BASE_URL,
            path: "/cloudwatch/home",
            query: { region: AwsJobLogHelper::AWS_REGION }.to_query,
            fragment: "logsV2:logs-insights#{query_detail}"
          )
          .to_s
      end

      private

      # Builds the part of the URL that contains information about how to query the logs.
      #
      # @see https://stackoverflow.com/a/60818699
      #
      # @param job_info [JobInfo] Contains info about the job to find logs for.
      #
      # @return [String] The escaped query detail parameter.
      def build_query_detail(job_info)
        query = {
          end: job_info.end_time.iso8601,
          start: job_info.start_time.iso8601,
          timeType: "ABSOLUTE",
          tz: "UTC",
          editorString: job_info.editor_string,
          isLiveTail: false,
          source: AwsJobLogHelper::LOG_GROUP
        }

        query.reduce("") do |query_detail, (key, value)|
          escaped_value = escape(value).tr("%", "*")

          append = if key == :source
                     # Source needs to be surrounded with parens: source~(~'value)
                     "#{key}#{lparen}#{equals(value)}#{escaped_value}#{rparen}"
                   else
                     # key~'value~
                     "#{key}#{equals(value)}#{escaped_value}#{endv}"
                   end

          query_detail + append
        end
      end

      def lparen
        double_escape("~(")
      end

      def rparen
        double_escape(")")
      end

      def endv
        double_escape("~")
      end

      def equals(value)
        double_escape(value.is_a?(String) ? "~'" : "~")
      end

      def escape(value)
        CGI.escape(value.to_s)
          .gsub("~", "%7E") # ~ is not escaped by default
          .gsub("+", "%20") # <space> is escaped as +, but it should be %20
      end

      def double_escape(value)
        escape(escape(value))
      end
    end
  end

  # Renders a AWS CLI command to find logs for an ActiveJob.
  class CommandRenderer
    class << self
      # @note This renderer renders a set of two commands. The first one starts a log query, and
      #   returns a query ID that can be used to get the results of the query. The renderer
      #   outputs the command to fetch query results with the query ID, and leaves it up to the user
      #   when to actually run it.
      #
      # @see https://docs.aws.amazon.com/cli/latest/reference/logs/start-query.html
      # @see https://docs.aws.amazon.com/cli/latest/reference/logs/get-query-results.html
      def render(job_info)
        <<~EOF
          aws logs start-query \\
            --log-group-name '#{AwsJobLogHelper::LOG_GROUP}' \\
            --start-time #{job_info.start_time_ms} \\
            --end-time #{job_info.end_time_ms} \\
            --query-string '#{job_info.editor_string}' \\
          | jq -r '. | "Get Results: [ aws logs get-query-results --query-id \\(.queryId) ]"'
        EOF
      end
    end
  end

  class << self
    # Gets an AWS CloudWatch URL to find logs for an ActiveJob.
    #
    # @example Using an ActiveJob (by default this will search for logs in the past day)
    #   job = VirtualHearings::DeleteConferencesJob.new
    #   job.perform_now
    #   puts AwsJobLogHelper.url_for_job_logs(job)
    #
    # @example Using a JobInfo
    #   start_time = Time.zone.now
    #   job = VirtualHearings::DeleteConferencesJob.new
    #   job.perform_now
    #   job_info = AwsJobLogHelper::JobInfo.from_active_job(job, start_time: start_time)
    #   puts AwsJobLogHelper.url_for_job_logs(job_info)
    #
    # @example With a job ID
    #   job_info = AwsJobLogHelper::JobInfo.new(VirtualHearings::DeleteConferencesJob, "id")
    #   puts AwsJobLogHelper.url_for_job_logs(job_info)
    #
    # @param job [ActiveJob, JobInfo] An ActiveJob or a JobInfo instance describing the job.
    #
    # @return [String] An AWS CloudWatch URL that finds logging for the job.
    def url_for_job_logs(job)
      render_query_with_renderer(job, UrlRenderer)
    end

    # Gets an AWS CLI command to find logs for an ActiveJob.
    #
    # @example Using an ActiveJob (by default this will search for logs in the past day)
    #   job = VirtualHearings::DeleteConferencesJob.new
    #   job.perform_now
    #   puts AwsJobLogHelper.command_for_job_logs(job)
    #
    # @example Using a JobInfo
    #   start_time = Time.zone.now
    #   job = VirtualHearings::DeleteConferencesJob.new
    #   job.perform_now
    #   job_info = AwsJobLogHelper::JobInfo.from_active_job(job, start_time: start_time)
    #   puts AwsJobLogHelper.command_for_job_logs(job_info)
    #
    # @example With a job ID
    #   job_info = AwsJobLogHelper::JobInfo.new(VirtualHearings::DeleteConferencesJob, "id")
    #   puts AwsJobLogHelper.command_for_job_logs(job_info)
    #
    # @param job [ActiveJob, JobInfo] An ActiveJob or a JobInfo instance describing the job.
    #
    # @return [String] An AWS CLI command that starts a query to find logs for the job.
    #   The returned command also generates a secondary command that you can use to get
    #   the results for the query.
    def command_for_job_logs(job)
      render_query_with_renderer(job, CommandRenderer)
    end

    private

    def render_query_with_renderer(job, renderer)
      job_info = if job.is_a?(JobInfo)
                   job
                 else
                   JobInfo.from_active_job(job)
                 end

      renderer.render(job_info)
    end
  end
end
