# frozen_string_literal: true

##
# Generates a pre-filtered AWS URL or AWS command to find logs for a Caseflow job

class AwsJobLogHelper
  # Describes an ActiveJob.
  class JobInfo
    attr_reader :job_class, :msg_id, :start_time, :end_time

    # @param job_class  [Class, String] Name of the ActiveJob class.
    # @param msg_id     [String] SQS message ID. This is the ID that appears in the log, and is unique per
    #                            message in the queue. This differs from the job ID, which can be different
    #                            for each time that a worker tries to process a message.
    # @param start_time [DateTime] Start of the datetime range to search (default is within the last day).
    # @param end_time   [DateTime] End of the datetime range to search.
    def initialize(job_class, msg_id, start_time: (Time.zone.now - 1.day), end_time: Time.zone.now)
      @job_class = job_class    # REQUIRED: Class of the Job
      @msg_id = msg_id          # REQUIRED: Unique SQS Message ID
      @start_time = start_time
      @end_time = end_time
    end

    def start_time_ms
      (start_time.to_f * 1000).to_i
    end

    def end_time_ms
      (end_time.to_f * 1000).to_i
    end

    # Builds the filter string to find the described job in AWS.
    #
    # @see https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax-examples.html
    #
    # @return [String] A query filter string to find the logging for the job in CloudWatch.
    def editor_string
      <<~EOF
        fields @timestamp, @message
        | parse "* * * ActiveJob/*/*/* *: *" as timestamp, pid, thread_id, job_class, queue_name, msg_id, level, message
        | sort @timestamp asc
        | filter (job_class="#{job_class}" and msg_id="#{msg_id}")
        | display level, message
      EOF
    end

    # Gets an AWS CloudWatch URL to find logs for an ActiveJob.
    #
    # @example With a SQS message ID
    #   puts AwsJobLogHelper::JobInfo.new(VirtualHearings::DeleteConferencesJob, "msg_id").url
    #
    # @return [String] An AWS CloudWatch URL that finds logging for the job.
    def url
      render_query_with_renderer(UrlRenderer)
    end

    # Gets an AWS CLI command to find logs for an ActiveJob.
    #
    # @example With a SQS message ID
    #   puts AwsJobLogHelper::JobInfo.new(VirtualHearings::DeleteConferencesJob, "msg_id").command
    #
    # @return [String] An AWS CLI command that starts a query to find logs for the job.
    #   The returned command also generates a secondary command that you can use to get
    #   the results for the query.
    def command
      render_query_with_renderer(CommandRenderer)
    end

    private

    def render_query_with_renderer(renderer)
      renderer.render(self)
    end
  end

  class Renderer
    # AWS Region in Production
    AWS_REGION = "us-gov-west-1"

    AWS_CONSOLE_BASE_URL = "console.amazonaws-us-gov.com"

    # AWS Cloudwatch Log group name for all Caseflow Jobs
    LOG_GROUP = {
      prod: "dsva-appeals-certification-prod/opt/caseflow-certification/src/log/caseflow-certification-sqs-worker.out",
      uat: "dsva-appeals-certification-uat/opt/caseflow-certification/src/log/caseflow-certification-sqs-worker.out"
    }.freeze

    def self.environment_log_group
      LOG_GROUP[Rails.deploy_env] || LOG_GROUP[:uat]
    end
  end

  # Renders a AWS CloudWatch URL to find logs for an ActiveJob.
  class UrlRenderer < Renderer
    class << self
      def render(job_info)
        # The URL fragment contains info about the query for logs. See `UrlRenderer#build_query_detail`
        # for documentation about how this section of the URL is structured.
        query_detail = "#{escape('?queryDetail=')}#{lparen}#{build_query_detail(job_info)}#{rparen}".tr("%", "$")

        URI::HTTPS
          .build(
            host: Renderer::AWS_CONSOLE_BASE_URL,
            path: "/cloudwatch/home",
            query: { region: Renderer::AWS_REGION }.to_query,
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
          source: environment_log_group
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
  class CommandRenderer < Renderer
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
            --log-group-name '#{environment_log_group}' \\
            --start-time #{job_info.start_time_ms} \\
            --end-time #{job_info.end_time_ms} \\
            --query-string '#{job_info.editor_string}' \\
          | jq -r '. | "Get Results: [ aws logs get-query-results --query-id \\(.queryId) ]"'
        EOF
      end
    end
  end
end
