# frozen_string_literal: true

# These are rules to help us codify our engineering norms for PRs.
# Please refer to the documentation here: http://danger.systems/ruby/

# Shared consts
CHANGED_FILES = (git.added_files + git.modified_files).freeze

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "WIP"

# Warn when there is a big PR
if git.lines_of_code > 500
  warn(
    "This is a Big PR. Try to break this down if possible. "\
    "[Stacked pull requests](https://unhashable.com/stacked-pull-requests-keeping-github-diffs-small/) " \
    "encourage more detailed and thorough code reviews"
  )
end

if git.modified_files.grep(/app\/services\//).any?
  warn(
    "This PR appears to affect one or more integrations. Make sure to test code in UAT before merging. "\
    "See these [instructions for deploying a custom branch to UAT](https://github.com/department-of-veterans-affairs/appeals-deployment/wiki/Appeals-Deployment---Deploy-Custom-Branch-to-UAT)."
  )
end

# Don't let testing shortcuts get into master by accident
if `git diff #{github.base_commit} spec/ | grep -E '(:focus => true)|(focus: true)'`.length > 1
  fail("focus: true is left in test")
end

# We must take care of our db schema.
if git.modified_files.grep(/db\/schema.rb/).any?
  warn("This PR changes the schema. Please use the PR template checklist.")
end

if git.modified_files.grep(/db\/etl\/schema.rb/).any?
  warn("This PR changes the etl schema. Please use the PR template checklist.")
end

new_db_migrations = git.modified_files.grep(/db\/migrate\//).any?
new_etl_migrations = git.modified_files.grep(/db\/etl\/migrate\//).any?

# migration without migrating
if new_db_migrations && git.modified_files.grep(/db\/schema.rb/).none?
  warn("This PR contains db migrations, but the schema.rb is not modified. Did you forget to run 'make migrate'?")
end

if new_etl_migrations && git.modified_files.grep(/db\/etl\/schema.rb/).none?
  warn("This PR contains etl migrations, but the etl schema.rb is not modified. Did you forget to run 'make migrate'?")
end

# migration without running rake db:docs
if (new_db_migrations || new_etl_migrations) && git.modified_files.grep(/docs\/schema/).none?
  warn("This PR contains one or more db migrations. Did you forget to run 'make docs'?")
end

# Encourage writing Storybook stories for React components
if CHANGED_FILES.grep(/\.jsx/).any?
  warn("This PR modifies React components — consider adding/updating corresponding Storybook file")
end

# We should not disable Rubocop rules unless there's a very good reason
result = git.diff.flat_map do |chunk|
  chunk.patch.lines.grep(/^\+\s*\w/).select { |added_line| added_line.match?(/rubocop:disable/) }
end

if !result.empty?
  warn(
    "This PR disables one or more Rubocop rules. " \
    "If there is a valid reason, please provide it in your commit message. " \
    "Otherwise, consider refactoring the code."
  )
end

# Make sure DB changes don't affect `rake db:seed`
result = git.diff.flat_map do |chunk|
  chunk.patch.lines.grep(/^\+\s*\w/).select { |added_line| added_line.match?(/remove_column|rename_column|drop_table/) }
end

if !result.empty?
  warn(
    "This PR makes DB changes that might affect the local seeds. " \
    "Please make sure `rake db:seed` still runs without issues."
  )
end

# If we're performing a migration against a table that is known to be large, make sure
# we've set connection timeouts appropriately.
KNOWN_LARGE_TABLES = %w[
  annotations
  api_views
  appeal_views
  claims_folder_searches
  documents
  documents_tags
  document_views
  hearing_views
  versions
].freeze

large_table_migration_pattern = /(add_index|add_column) :(#{KNOWN_LARGE_TABLES.join('|')})/
migrations_on_large_tables = git.diff.flat_map do |chunk|
  chunk.patch.lines.grep(/^\+\s*\w/).select do |added_line|
    added_line.match?(large_table_migration_pattern)
  end
end

if migrations_on_large_tables.any?
  warn(
    "This PR contains DB migrations on large tables. Be sure to set connection statement_timeout accordingly."
  )
end

contains_new_index = git.diff.flat_map do |chunk|
  chunk.patch.lines.grep(/^\+\s*\w/).select do |added_line|
    added_line.match?(/add_index/)
  end
end

if contains_new_index.any?
  warn(
    "This PR contains DB migrations that use add_index. Prefer Caseflow::Migration with add_safe_index instead. " \
    "See https://github.com/department-of-veterans-affairs/caseflow/wiki/Writing-DB-migrations#index-creation-should-go-in-its-own-migration-file"
  )
end

# Check for `User.find_by(css_id:`
result = git.diff.flat_map do |chunk|
  chunk.patch.lines.grep(/^\+\s*\w/).select { |added_line| added_line.match?(/User.find_by\(css_id:/) }
end

if !result.empty?
  warn(
    "This PR uses `User.find_by(css_id:`, which uses a sequential scan on the DB. " \
    "Instead, use `User.find_by_css_id` to use the `index_users_unique_css_id` index."
  )
end
