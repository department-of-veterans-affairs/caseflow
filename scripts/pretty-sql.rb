# frozen_string_literal: true

# bundle exec rails runner scripts/pretty-sql.rb

require 'anbt-sql-formatter/formatter'

def formatter
  @formatter ||= build_formatter
end

def build_formatter
  rule = AnbtSql::Rule.new
  rule.keyword = AnbtSql::Rule::KEYWORD_UPPER_CASE
  %w[count sum substr date].each { |func_name| rule.function_names << func_name.upcase }
  rule.indent_string = '  '
  AnbtSql::Formatter.new(rule)
end

DRY_RUN = ARGV.include?("--dry_run")

for file in ARGV.reject { |arg| arg =~ /^--/ }
  puts file
  buf = File.read(file)
  pretty_sql = formatter.format(buf)

  if DRY_RUN
    puts "Skipping re-write of #{file} due to --dry_run"
    next
  end

  File.open(file, 'w') { |f| f.puts pretty_sql }
end
