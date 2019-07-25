# frozen_string_literal: true

class Api::DecisionReviewErrorCollection
  # an error collection is immutable. all errors are added at initialization

  # children must define ERROR_CLASS

  attr_reader :errors

  def initialize(*args)
    # arguments
    #   0 args - the collection will be 1 default error
    #   1 hash argument - the collection will be a single error
    #                     based off of the kwargs provided
    #   1 array argument - an array of hashes, each hash being
    #                      the kwargs for creating an error
    raise ArgumentError, "too many args (specify no args or 1 arg)" if args.length > 1

    array_of_error_creation_instructions = (
      if args.empty?
        [{}]
      else
        case arg[0]
        when Hash
          [arg[0]]
        when Array
          arg[0]
        else
          raise ArgumentError, "if arg specified, it must be a hash or an array"
        end
      end
    )

    @errors = array_of_error_creation_instructions.map { |hash| ERROR_CLASS.new(hash) }
    raise StandardError, "cannot create an empty collection" if errors.empty? # overly cautious
  end

  # use the highest status as the status of the collection
  def status
    errors.map(&:status).max
  end

  # JSON:API json
  def as_json
    { errors: errors.map(&:as_json) }
  end

  def render_options
    { json: as_json, status: status }
  end
end
