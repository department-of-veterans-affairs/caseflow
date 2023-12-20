# frozen_string_literal: true

# bundle exec rails runner scripts/duplicate_decass_deleter.rb
# bundle exec rails runner scripts/duplicate_decass_deleter.rb --nodry_run

def sql_fmt(attribute)
  if attribute.nil?
    return "is null"
  end
  if attribute.is_a? Date
    return "= to_date('#{attribute}', 'YYYY-MM-DD')"
  end
  if attribute.is_a? Numeric
    return "= #{attribute}"
  end
  if attribute.is_a? String
    return "= '#{attribute}'"
  end

  fail attribute.inspect
end

# rubocop:disable Metrics/AbcSize
def predicate_from_record(record, limit)
  <<EOS.strip_heredoc
    rownum <= #{limit} and
    defolder #{sql_fmt(record.defolder)} and
    deatty #{sql_fmt(record.deatty)} and
    deteam #{sql_fmt(record.deteam)} and
    depdiff #{sql_fmt(record.depdiff)} and
    defdiff #{sql_fmt(record.defdiff)} and
    deassign #{sql_fmt(record.deassign)} and
    dereceive #{sql_fmt(record.dereceive)} and
    dehours #{sql_fmt(record.dehours)} and
    deprod #{sql_fmt(record.deprod)} and
    detrem #{sql_fmt(record.detrem)} and
    dearem #{sql_fmt(record.dearem)} and
    deoq #{sql_fmt(record.deoq)} and
    deadusr #{sql_fmt(record.deadusr)} and
    deadtim #{sql_fmt(record.deadtim)} and
    deprogrev #{sql_fmt(record.deprogrev)} and
    deatcom #{sql_fmt(record.deatcom)} and
    debmcom #{sql_fmt(record.debmcom)} and
    demdusr #{sql_fmt(record.demdusr)} and
    demdtim #{sql_fmt(record.demdtim)} and
    delock #{sql_fmt(record.delock)} and
    dememid #{sql_fmt(record.dememid)} and
    decomp #{sql_fmt(record.decomp)} and
    dedeadline #{sql_fmt(record.dedeadline)} and
    deicr #{sql_fmt(record.deicr)} and
    defcr #{sql_fmt(record.defcr)} and
    deqr1 #{sql_fmt(record.deqr1)} and
    deqr2 #{sql_fmt(record.deqr2)} and
    deqr3 #{sql_fmt(record.deqr3)} and
    deqr4 #{sql_fmt(record.deqr4)} and
    deqr5 #{sql_fmt(record.deqr5)} and
    deqr6 #{sql_fmt(record.deqr6)} and
    deqr7 #{sql_fmt(record.deqr7)} and
    deqr8 #{sql_fmt(record.deqr8)} and
    deqr9 #{sql_fmt(record.deqr9)} and
    deqr10 #{sql_fmt(record.deqr10)} and
    deqr11 #{sql_fmt(record.deqr11)} and
    dedocid #{sql_fmt(record.dedocid)} and
    derecommend #{sql_fmt(record.derecommend)}
EOS
end
# rubocop:enable Metrics/AbcSize

DRY_RUN = !ARGV.include?("--nodry_run")
if !DRY_RUN
  puts "WARNING: This is NOT a dry run."
end

defolders = VACOLS::Decass.select("defolder")
  .where("deadtim >= ?", Date.new(2018, 8, 16))
  .group("defolder").having("count(*) > 1").map(&:defolder)
puts "Found #{defolders.length} cases with too many Decass records"
num_deleted = 0
defolders.each do |defolder|
  puts "Processing case #{defolder}"
  VACOLS::Decass.transaction do
    records = VACOLS::Decass.where(defolder: defolder)
    records_with_json_rep = {}
    records.each do |r|
      j = r.as_json
      if records_with_json_rep[j].nil?
        records_with_json_rep[j] = []
      end
      records_with_json_rep[j].push(r)
    end
    records_with_json_rep.each_pair do |k, records_duplicate|
      if records_duplicate.length == 1
        next
      end

      query_select = <<EOS.strip_heredoc
        select 1
        from decass
        where #{predicate_from_record(records_duplicate[0], records_duplicate.length - 1)}
EOS
      num_found = 0
      cursor = VACOLS::Decass.connection.execute(query_select)
      num_found += 1 while cursor.fetch
      unless num_found == records_duplicate.length - 1
        puts "Skipping records because query found #{num_found} instead of #{records_duplicate.length - 1} records to "\
          "delete. The dates probably didn't match."
        next
      end

      puts "Deleting #{records_duplicate.length - 1} duplicates of #{k}"
      query_delete = <<EOS.strip_heredoc
        delete
        from decass
        where #{predicate_from_record(records_duplicate[0], records_duplicate.length - 1)}
EOS
      if !DRY_RUN
        VACOLS::Decass.connection.execute(query_delete)
      end
      num_deleted += records_duplicate.length - 1
    end
    puts
  end
end
puts "Deleted #{num_deleted} duplicate records"
