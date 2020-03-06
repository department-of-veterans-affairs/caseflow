# frozen_string_literal: true

# bundle exec rails runner scripts/pretty-sql.rb

require "anbt-sql-formatter/formatter"

DRY_RUN = ARGV.include?("--dry_run")

class SQLFormatter
  def initialize
    @formatter = self.class.build_formatter
  end

  def format(buf)
    @formatter.format(buf)
  end

  def self.build_formatter
    rule = AnbtSql::Rule.new
    rule.keyword = AnbtSql::Rule::KEYWORD_UPPER_CASE
    rule.kw_nl_x = %w[OR THEN ELSE WHEN]
    %w[count sum substr date].each { |func_name| rule.function_names << func_name.upcase }
    rule.indent_string = "  "
    AnbtSql::Formatter.new(rule)
  end
end

formatter = SQLFormatter.new
ARGV.reject { |arg| arg =~ /^--/ }.each do |file|
  puts file
  buf = File.read(file)
  pretty_sql = formatter.format(buf)

  if DRY_RUN
    puts "Skipping re-write of #{file} due to --dry_run"
    next
  end

  File.open(file, "w") { |f| f.puts pretty_sql }
end
