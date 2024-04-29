# frozen_string_literal: true

require "singleton"

class Sequence
  include Singleton
  attr_reader :count, :current_year, :year_format

  def initialize
    @count = 0
    @current_year = Time.zone.today.year
    @year_format = "%Y"
  end

  def next
    current_year = Time.zone.today.year

    if @current_year != current_year
      @current_year = current_year
      @count = 0
    end

    if @count == 9999
      @count = 0
      @year_format = "%y" if @year_format == "%Y"
    end

    @count += 1
    "#{formatted_year}-#{format('%04d', @count)}"
  end

  private

  def formatted_year
    @year_format == "%y" ? @current_year.to_s[-2..-1] : @current_year
  end
end
