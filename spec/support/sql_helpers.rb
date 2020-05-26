# frozen_string_literal: true

module SQLHelpers
  def read_sql(file_name)
    base_dir = Rails.root.join("app", "sql")
    sql_file = File.join(base_dir, file_name + ".sql")
    if !File.exist?(sql_file)
      sql_file = File.join(base_dir, file_name)
    end
    File.read(sql_file)
  end

  def to_sql_query_hash(statements)
    queries_hash = {}
    statements.each do |statement|
      query_name = statement.scan(/@QUERY_NAME: *(.*)$/)&.last&.first
      queries_hash[query_name] = statement if query_name
    end
    queries_hash
  end

  def read_sql_as_hash(file_name)
    sql_statements = read_sql(file_name).split(";")
    to_sql_query_hash(sql_statements)
  end

  def execute_sql(file_name)
    sql = read_sql(file_name)
    result = ApplicationRecord.connection.exec_query(sql)
    result.to_ary
  end

  def expect_sql(file_name)
    result = execute_sql(file_name)
    expect(result)
  end
end
