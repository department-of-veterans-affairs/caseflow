# These are rules to help us codify our engineering norms for PRs.
# Please refer to the documentation here: http://danger.systems/ruby/

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "WIP"

# Warn when there is a big PR
warn("This is a Big PR. Try to break this down if possible.") if git.lines_of_code > 500

# Don't let testing shortcuts get into master by accident
if `git diff #{github.base_commit} spec/ | grep -E '(:focus => true)|(focus: true)'`.length > 1
  fail("focus: true is left in test")
end

# We must take care of our VACOLS models.  Remind developers to test this thoroughly
if !git.modified_files.grep(/app\/models\/vacols/).empty?
  warn("This PR changes VACOLS models.  Please ensure this is tested against a UAT VACOLS instance")
end
