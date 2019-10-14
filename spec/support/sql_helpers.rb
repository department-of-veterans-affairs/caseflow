# frozen_string_literal: true

module SQLHelpers
  def execute_sql(file_name)
    base_dir = Rails.root.join("app", "sql")
    sql_file = File.join(base_dir, file_name + ".sql")
    if !File.exist?(sql_file)
      sql_file = File.join(base_dir, file_name)
    end
    sql = File.read(sql_file)

    result = ApplicationRecord.connection.exec_query(sql)
    result.to_ary
  end

  def expect_sql(file_name)
    result = execute_sql(file_name)
    expect(result)
  end
end
