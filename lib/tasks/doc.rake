# frozen_string_literal: true

require "rails_erd/domain"
require "csv"

namespace :doc do
  def table_comments
    sql = <<-SQL
      SELECT c.table_schema,c.table_name,c.column_name,pgd.description
      FROM pg_catalog.pg_statio_all_tables as st
        inner join pg_catalog.pg_description pgd on (pgd.objoid=st.relid)
        inner join information_schema.columns c on (pgd.objsubid=c.ordinal_position
        and c.table_schema=st.schemaname and c.table_name=st.relname)
    SQL
    comments = {}
    exec_sql(sql).each do |tuple|
      table_name = tuple["table_name"]
      comments[table_name] ||= {}
      comments[table_name][tuple["column_name"]] = tuple["description"]
    end
    comments
  end

  def comment_for_table(table_name)
    table_comment_sql = "select obj_description(oid) from pg_class where relkind='r' and relname='?'"
    exec_sql(table_comment_sql.sub("?", table_name)).first["obj_description"]
  end

  def exec_sql(sql)
    db_connection.exec_query(sql).to_hash
  end

  def db_connection
    @example_klass.connection
  end

  def indexed?(table_name, column_name)
    @indexes ||= build_indexes
    @indexes.dig(table_name, column_name)
  end

  def build_indexes
    indexes = {}
    db_connection.tables.map do |table|
      indexes[table] = {}
      idxs = db_connection.indexes(table)
      idxs.each do |idx|
        Array(idx.columns).each { |col| indexes[table][col] = true }
      end
    end
    indexes
  end

  desc "Generate documentation for db schema"
  task schema: :environment do
    schema_name = ENV.fetch("SCHEMA") # die if not set

    $VERBOSE = nil # turn off warnings about already initialized constants
    Rails.application.eager_load!

    domain = RailsERD::Domain.generate

    # we do this evil instance_variable_get to make sure we are talking to the correct db.
    @example_klass = domain.instance_variable_get(:@source_models).first
    comments = table_comments

    csv_file = Rails.root.join("docs/schema/#{schema_name}.csv")
    CSV.open(csv_file, "wb") do |csv|
      csv << ["Table", "Column", "Type", "Required", "Primary Key", "Unique", "Index", "Description"]
      domain.entities.each do |entity|
        table_name = entity.model.table_name
        csv << [table_name, nil, nil, nil, nil, nil, nil, comment_for_table(table_name)]
        entity.attributes.each do |attr|
          comment = comments.dig(table_name, attr.name)
          csv << [
            table_name,
            attr.name,
            attr.type_description,
            attr.mandatory?,
            attr.primary_key?,
            attr.unique?,
            indexed?(table_name, attr.name),
            comment
          ]
        end
      end
    end
  end
end
