# frozen_string_literal: true

describe "Line of Business example", :postgres do
  include SQLHelpers

  let!(:vha_request_issue) { create(:request_issue, benefit_type: "vha") }

  it "compiles SQL" do
    sql_statements = read_sql("line-of-business").split(";")
    sql_statements.each do |sql|
      result = ApplicationRecord.connection.exec_query(sql)
      expect(result.to_ary).to be_a(Array)
      # pp result.to_ary
    end
  end
end
