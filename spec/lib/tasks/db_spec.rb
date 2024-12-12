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
  
        Prefer using the appropriate database-specific task below:

          db:reset:primary  # Reset the primary database
          db:reset:etl      # Reset the etl database
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

  describe "setup" do
    subject { Rake::Task["db:setup"].invoke }

    it "no-ops and outputs a helpful message" do
      expected_output = <<~HEREDOC

        db:setup is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:setup:primary  # Setup the primary database
          db:setup:etl      # Setup the etl database
      HEREDOC

      expect { subject }.to output(expected_output).to_stdout
    end
  end
end
# rubocop:enable Layout/HeredocIndentation
