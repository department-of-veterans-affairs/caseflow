# frozen_string_literal: true

# Export a psql table to a csv file in an S3 bucket

require "English"

class CsvToS3Exporter
  # rubocop:disable Metrics/ParameterLists
  def initialize(table:, bucket:, region: "us-gov-west-1", date: Time.zone.today.iso8601, compress: true, test: false)
    @date = date
    @table = table
    @bucket = bucket
    @region = region
    @compress = compress
    @test = test

    set_psql_url
  end
  # rubocop:enable Metrics/ParameterLists

  def call
    called_at = Time.zone.now
    rows = run(csv_cmd)
    rows_copied = rows.tr("COPY ", "").to_i
    line_count = run("wc -l #{tmp_file}")
    unless (rows_copied + 1) == line_count.strip.to_i
      fail "CSV appears truncated. Expected #{rows_copied} but found #{line_count.strip}"
    end

    checksum = run(checksum_cmd)
    run(s3_cp_cmd)
    meta = { rows: rows_copied, time: called_at.iso8601, checksum: checksum.strip.gsub(/ .*/, "") }
    run(s3_cp_meta_cmd(meta))
    meta
  end

  private

  attr_reader :table, :bucket, :date, :compress, :region, :test

  def run(cmd)
    Rails.logger.info(cmd)
    output = `#{cmd}`

    if $CHILD_STATUS != 0
      fail "#{cmd} failed: #{$CHILD_STATUS} #{$ERROR_INFO}"
    end

    output
  end

  def test?
    !!test
  end

  def compress?
    !!compress
  end

  def csv_file
    "#{date}-caseflow-#{table}.csv"
  end

  def tmp_file
    @tmp_file ||= Tempfile.new(csv_file).path # wrap in Tempfile so it cleans itself up
  end

  def set_psql_url
    conf = ActiveRecord::Base.connection_config
    ENV["POSTGRES_URL"] ||= "postgres://#{conf[:username]}:#{conf[:password]}@#{conf[:host]}/#{conf[:database]}"
  end

  def csv_cmd
    "psql \$POSTGRES_URL -c '\\copy #{table} to #{tmp_file} with (format csv, header, force_quote *)'"
  end

  def bucket_target
    "s3://#{bucket}/#{date}/#{csv_file}"
  end

  def s3_cp_cmd
    return "cp #{tmp_file} #{test}" if test?

    if compress?
      "gzip -c #{tmp_file} | aws --region #{region} s3 cp - #{bucket_target}.gz"
    else
      "aws --region #{region} s3 cp #{tmp_file} #{bucket_target}"
    end
  end

  def s3_cp_meta_cmd(meta)
    meta_json = meta.to_json

    return "echo '#{meta_json}' > #{test}.meta" if test?

    "echo '#{meta_json}' | aws --region #{region} s3 cp - #{bucket_target}.meta"
  end

  def checksum_cmd
    "sha256sum #{tmp_file}"
  end
end
