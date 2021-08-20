# frozen_string_literal: true

require "rails_erd/domain"
require "csv"

# required for ERD diagrams
require "ruby-graphviz"
require "tasks/support/erd_record_associations.rb"
require "tasks/support/erd_graph_styling.rb"

namespace :doc do
  desc "prepare environment"
  task prepare: :environment do
    $VERBOSE = nil # turn off warnings about already initialized constants
    Rails.application.eager_load! # so that ApplicationRecord.descendants returns all record types
  end

  namespace :csv do
    # SQL is all psql-specific so we can't do VACOLS
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

    def pretty_boolean(bool)
      return "x" if bool

      nil
    end

    desc "Generate csv for db schema"
    task schema: :prepare do
      schema_name = ENV.fetch("SCHEMA") # die if not set
      ENV.fetch("ERD_BASE") # we just want it defined explicitly for RailsERD::Domain.generate

      domain = RailsERD::Domain.generate

      # we do this evil instance_variable_get to make sure we are talking to the correct db.
      @example_klass = domain.instance_variable_get(:@source_models).first
      comments = table_comments

      csv_file = Rails.root.join("docs/schema/#{schema_name}.csv")
      CSV.open(csv_file, "wb") do |csv|
        csv << ["Table", "Column", "Type", "Required", "Primary Key", "Foreign Key", "Unique", "Index", "Description"]

        domain.entities.each do |entity|
          next unless entity.model

          next if entity.virtual? # only fronting actual tables

          table_name = entity.model.table_name

          csv << [table_name, nil, nil, nil, nil, nil, nil, nil, comment_for_table(table_name)]
          entity.attributes.each do |attr|
            comment = comments.dig(table_name, attr.name)
            csv << [
              table_name,
              attr.name,
              attr.type_description,
              pretty_boolean(attr.mandatory?),
              pretty_boolean(attr.primary_key?),
              pretty_boolean(attr.foreign_key?),
              pretty_boolean(attr.unique?),
              pretty_boolean(indexed?(table_name, attr.name)),
              comment
            ]
          end
        end
      end
    end
  end

  namespace :belongs_to do
    include ErdRecordAssociations
    include ErdGraphStyling

    def record_classes
      return @record_classes if @record_classes

      base_class = ENV.fetch("ERD_BASE", "ApplicationRecord").constantize
      # The ordering of this array affects the graph layout
      @record_classes = [LegacyAppeal, Appeal] | base_class.descendants
    end

    def exclude_verbose_classes(record_classes)
      # To-do: create edges for subclass `belongs_to` relationships because
      # some Task and Claimant subclasses may have additional `belongs_to`.
      # For now, we're ignoring relationships for those subclasses.
      record_classes - Task.descendants - [Intake] - Claimant.descendants - RequestIssue.descendants
    end

    def save_dot_file(graph, file_path)
      output_string = graph.output(dot: String)
      File.open(file_path, "w") do |file|
        # To easily see file differences, remove attributes calculated by graphviz:
        # remove 'pos', 'lp' (label position), and 'rects' attributes
        output_string.gsub!(/\b(pos|head_lp|lp|rects)="[^"]*"/m, "")
        # remove 'width' and 'height' attributes
        output_string.gsub!(/\b(width|height)=[0-9\.]*/m, "")
        # And also remove extraneous commas resulting from attribute removal
        output_string.gsub!(/^\t*,\n/, "").gsub!(/\[,/, "[")
        file.write output_string.force_encoding("UTF-8")
      end
    end

    def save_graph_files(graph, graph_filename)
      schema_name = ENV.fetch("SCHEMA") # fails if not set
      target_dir = Rails.root.join("docs/schema/")

      save_dot_file(graph, target_dir.join("#{schema_name}-#{graph_filename}.dot"))
      if update_schema_images?
        graph.save(
          png: target_dir.join("#{schema_name}-#{graph_filename}.png"),
          svg: target_dir.join("#{schema_name}-#{graph_filename}.svg")
        )
      end
    end

    def update_schema_images?
      ENV.fetch("UPDATE_SCHEMA_ERD_IMAGES", nil)
    end

    desc "Generate belongs_to ERD"
    task erd: :prepare do
      node_classes = exclude_verbose_classes(record_classes)

      # Subclasses ERD
      GraphViz.new(:subclasses, type: :digraph, rankdir: "LR", splines: "line") do |graph|
        add_subclass_edges(graph, record_classes - [CaseflowRecord, VACOLS::Record, ETL::Record])

        style_nodes(graph)
        save_graph_files(graph, "subclasses")
      end

      # Belongs_to ERD
      GraphViz.new(:belongs_to_erd, type: :digraph, rankdir: "LR") do |graph|
        add_association_edges(graph, node_classes)
        add_polymorphic_nodes(graph)
        add_polymorphic_edges(graph)

        style_nodes(graph)
        save_graph_files(graph, "belongs_to_erd")
      end

      # Belongs_to ERD combined with Subclasses ERD
      GraphViz.new(:belongs_to_erd_subclasses, type: :digraph, rankdir: "LR") do |graph|
        add_association_edges(graph, node_classes)
        add_polymorphic_nodes(graph)
        add_polymorphic_edges(graph)

        # To avoid clutter, don't show the numerous Task subclasses
        relevant_classes = record_classes - Task.descendants - [Task, CaseflowRecord, VACOLS::Record, ETL::Record]
        add_subclass_edges(graph, relevant_classes)

        style_nodes(graph)
        save_graph_files(graph, "belongs_to_erd-subclasses")
      end
    end
  end

  desc "Generate documentation for db schema"
  task schema: ["csv:schema", "belongs_to:erd"]
end
