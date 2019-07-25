# frozen_string_literal: true

class Api::HigherLevelReviewErrorCollection
  def initialize(*args)
    # accepts either a single argument (an error hash or an array of error hashes) or no arguments

    @errors = (
      if args.empty?
        [{}]
      else
        arg = args[0]
        arg.is_a?(Array) ? arg : [arg]
      end
    ).map { |e| Error.new(e) }
  end

  attr_reader :errors

  # returns statuses as integers
  def statuses
    errors.map do |error|
      status = error.status

      case status
      when Numeric then status
      when Symbol then self.class.status_symbol_to_int status
      else
        number = begin; Integer status; rescue StandardError; nil; end
        number || Status.int(status.to_sym)
      end
    end
  end

  def statuses_to_sym
    statuses.map { |i| Status.sym i }
  end

  def status
    statuses.max || Error::DEFAULT_STATUS
  end

  def errors_as_json
    errors.map(&:as_json)
  end

  def as_json
    { errors: errors_as_json }
  end

  def render_hash
    { json: as_json, status: status }
  end

  class Error
    class << self
      def code_from_title(title)
        title.split(" ").join("_").downcase.gsub(/[^0-9a-z_]/i, "")
      end

      def title_from_code(code)
        code.split("_").join(" ").capitalize
      end
    end

    DEFAULT_TITLE = "Unknown error."
    DEFAULT_CODE = code_from_title DEFAULT_TITLE
    DEFAULT_STATUS = 422

    def initialize(options)
      @status, @title, @code = options.values_at :status, :title, :code
    end

    def status
      @status || DEFAULT_STATUS
    end

    def code
      @code || (@title && code_from_title(@title)) || DEFAULT_CODE
    end

    def title
      @title || (@code && title_from_code(@code)) || DEFAULT_TITLE
    end

    def inspect
      { status: status, title: title, code: code }
    end

    delegate :as_json, to: :inspect
  end

  class << self
    # verifies that status code is a valid one
    # note: instead of a boolean, it returns either nil (invalid status) or the status code swapped
    # --swapped as in:
    #   given something number-like, returns a symbol
    #   given something symbol-like, returns an int
    def valid_status(status)
      int = begin
              Integer status
            rescue
              nil
            end
      sym = status.to_sym
      Rack::Utils::HTTP_STATUS_CODES[int] || Rack::Utils::SYMBOL_TO_STATUS_CODE[sym]
    end

    def invalid_status_error(status)
      raise ArgumentError, "Invalid status: #{status}"
    end
  end
end
