class AddTagTextIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index(:tags, [:text], unique: true, algorithm: :concurrently)
  end
end

# select
#     t.relname as table_name,
#     i.relname as index_name,
#     a.attname as column_name
# from
#     pg_class t,
#     pg_class i,
#     pg_index ix,
#     pg_attribute a
# where
#     t.oid = ix.indrelid
#     and i.oid = ix.indexrelid
#     and a.attrelid = t.oid
#     and a.attnum = ANY(ix.indkey)
#     and t.relkind = 'r'
#     and t.relname like 'tag%'
# order by
#     t.relname,
#     i.relname;