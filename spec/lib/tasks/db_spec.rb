# frozen_string_literal: true

# rubocop:disable Layout/HeredocIndentation
describe "db" do
  include_context "rake"

  describe "create" do
    subject { Rake::Task["db:create"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:create is prohibited.
  
        Prefer using the appropriate database-specific task below:
        
          db:create:primary  # Create primary database for current environment
          db:create:etl      # Create etl database for current environment
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "drop" do
    subject { Rake::Task["db:drop"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:drop is prohibited.
  
        Prefer using the appropriate database-specific task below:
        
          db:drop:primary  # Drop primary database for current environment
          db:drop:etl      # Drop etl database for current environment
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "migrate" do
    subject { Rake::Task["db:migrate"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:migrate is prohibited.
  
        Prefer using the appropriate database-specific task below:
        
          db:migrate:primary  # Migrate primary database for current environment
          db:migrate:etl      # Migrate etl database for current environment
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "migrate:down" do
    subject { Rake::Task["db:migrate:down"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:migrate:down is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:migrate:down:primary  # Runs the "down" for a given migration VERSION on the primary database
          db:migrate:down:etl      # Runs the "down" for a given migration VERSION on the etl database
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "migrate:redo" do
    subject { Rake::Task["db:migrate:redo"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:migrate:redo is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:migrate:redo:primary  # Rolls back primary database one migration and re-migrates up (options: STEP=x, VERSION=x)
          db:migrate:redo:etl      # Rolls back etl database one migration and re-migrates up (options: STEP=x, VERSION=x)
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "migrate:status" do
    subject { Rake::Task["db:migrate:status"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:migrate:status is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:migrate:status:primary  # Display status of migrations for primary database
          db:migrate:status:etl      # Display status of migrations for etl database
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "migrate:up" do
    subject { Rake::Task["db:migrate:up"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:migrate:up is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:migrate:up:primary  # Runs the "up" for a given migration VERSION on the primary database
          db:migrate:up:etl      # Runs the "up" for a given migration VERSION on the etl database
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "reset" do
    subject { Rake::Task["db:reset"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:reset is prohibited.
  
        Prefer using the appropriate sequence of database-specific tasks below:

          db:drop:primary db:create:primary db:schema:load:primary db:seed  # Reset the primary database
          db:drop:etl db:create:etl db:schema:load:etl db:seed              # Reset the etl database
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "rollback" do
    subject { Rake::Task["db:rollback"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:rollback is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:rollback:primary  # Rollback primary database for current environment (specify steps w/ STEP=n)
          db:rollback:etl      # Rollback etl database for current environment (specify steps w/ STEP=n)
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "schema:dump" do
    subject { Rake::Task["db:schema:dump"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:schema:dump is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:schema:dump:primary  # Creates a database schema file (either db/schema.rb or db/structure.sql, depending on `config.active_record.schema_format`) for primary database
          db:schema:dump:etl      # Creates a database schema file (either db/schema.rb or db/structure.sql, depending on `config.active_record.schema_format`) for etl database
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "schema:load" do
    subject { Rake::Task["db:schema:load"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:schema:load is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:schema:load:primary  # Loads a database schema file (either db/schema.rb or db/structure.sql, depending on `config.active_record.schema_format`) into the primary database
          db:schema:load:etl      # Loads a database schema file (either db/schema.rb or db/structure.sql, depending on `config.active_record.schema_format`) into the etl database
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "setup" do
    subject { Rake::Task["db:setup"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:setup is prohibited.
  
        Prefer using the appropriate sequence of database-specific tasks below:

          db:create:primary db:schema:load:primary db:seed  # Setup the primary database
          db:create:etl db:schema:load:etl db:seed          # Setup the etl database
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "test:load" do
    subject { Rake::Task["db:test:load"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:test:load is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:test:load:primary  # Recreate the primary test database from the current schema
          db:test:load:etl      # Recreate the etl test database from the current schema
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "test:load_schema" do
    subject { Rake::Task["db:test:load_schema"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:test:load_schema is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:test:load_schema:primary  # Recreate the primary test database from an existent schema file (schema.rb or structure.sql, depending on `config.active_record.schema_format`)
          db:test:load_schema:etl      # Recreate the etl test database from an existent schema file (schema.rb or structure.sql, depending on `config.active_record.schema_format`)
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "test:prepare" do
    subject { Rake::Task["db:test:prepare"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:test:prepare is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:test:prepare:primary  # Load the schema for the primary test database
          db:test:prepare:etl      # Load the schema for the etl test database
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end

  describe "test:purge" do
    subject { Rake::Task["db:test:purge"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:test:purge is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:test:purge:primary  # Empty the primary test database
          db:test:purge:etl      # Empty the etl test database
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end
end
# rubocop:enable Layout/HeredocIndentation
