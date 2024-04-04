StrongMigrations.start_after = 20190111000717
StrongMigrations.auto_analyze = true

# Customized error message when a new migration uses `add_index` non-concurrently
StrongMigrations.error_messages[:add_index] = <<~TEXT
  Adding a non-concurrent index locks the table for writes.
  Instead, prefer using `Caseflow::Migrations::AddIndexConcurrently #add_safe_index`:
   
      class YourMigrationName < ActiveRecord::Migration%{migration_suffix}
        include Caseflow::Migrations::AddIndexConcurrently
        
        def change
          add_safe_index # add args here...
        end
      end

  Nota Bene: Since adding indexes concurrently must occur outside of a transaction, 
  one should avoid mixing in other DB changes when doing so. It is strongly recommended 
  to segregate index additions from other DB changes in a separate migration.
  TEXT
