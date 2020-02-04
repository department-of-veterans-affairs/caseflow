# frozen_string_literal: true

class QueueFilterParameter
  include ActiveModel::Model

  validates :column, presence: true
  validate :values_is_array

  attr_accessor :column, :values

  def initialize(args)
    super
    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  def self.from_string(filter_string)
    # Transform the filter from a string to a hash and create an object from that hash.
    # "col=docketNumberColumn&val=legacy,evidence_submission"
    # ->
    # { "col": "docketNumberColumn", "val": ["legacy", "evidence_submission"] }
    filter_hash = Rack::Utils.parse_query(filter_string)
    values = filter_hash["val"]&.split(",")&.map { |value| escaped_value(value) }

    new(column: filter_hash["col"], values: values)
  end

  def self.from_suggested_location_col_filter_string(filter_string)
    # The from_string method does not work for suggestedLocation column
    # in assign hearings table because the row data has comma in it.
    # This method preserves the comma and returns correct filter params
    # "col=suggestedLocation&val=New York, NY(RO), San Francisco, CA(VA)"
    # ->
    # { "col": "suggestedLocation", "val": ["New York, NY(RO)", "San Francisco, CA(VA)"] }
    filter_hash = Rack::Utils.parse_query(filter_string)
    values = []
    arr = filter_hash["val"].split(",")
    if arr.include? (URI.escape(COPY::NULL_FILTER_LABEL))
      arr.reject! { |item| item == URI.escape(COPY::NULL_FILTER_LABEL) }
      values += [nil]
    end
    arr.each_slice(2) do |loc|
      values << escaped_value(loc.join(","))
    end
    
    new(column: filter_hash["col"], values: values)
  end

  def self.escaped_value(value)
    (URI.unescape(value) == COPY::NULL_FILTER_LABEL) ? nil : URI.unescape(value)
  end

  private

  def values_is_array
    errors.add(:values, "must be an array") unless values&.is_a?(Array)
  end
end
