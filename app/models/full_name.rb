# frozen_string_literal: true

class FullName
  attr_accessor :first_name, :middle_initial, :last_name

  class InvalidFormatError < StandardError; end

  def initialize(first_name, middle_initial, last_name)
    self.first_name = first_name
    self.middle_initial = middle_initial
    self.last_name = last_name
  end

  def to_s
    formatted(:readable_short)
  end

  # Format the name. Possible formats are:
  # :readable_full => Shane A Russell
  # :readable_short => Shane Russell
  # :form => Russell, Shane, A
  # :readable_mi_formatted => Shane A. Russell (middle inital formatted)
  # :readable_fi_last_formatted => M. Jordan
  def formatted(format)
    case format
    when :readable_full
      [first_name, middle_initial, last_name].select(&:present?).join(" ").titleize
    when :readable_full_nonformatted
      [first_name, middle_initial, last_name].select(&:present?).join(" ")
    when :readable_mi_formatted
      [first_name, middle_initial + ".", last_name].select(&:present?).join(" ").titleize
    when :readable_fi_last_formatted
      [first_name[0] + ".", last_name].select(&:present?).join(" ").titleize
    when :readable_short
      [first_name, last_name].select(&:present?).join(" ").titleize
    when :form
      [last_name, first_name, middle_initial].select(&:present?).join(", ")
    else
      fail InvalidFormatError
    end
  end
end
