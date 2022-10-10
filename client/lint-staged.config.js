// lint-staged.config.js
module.exports = {
  '../**/*.rb': (files) =>
    `bundle exec rubocop ${files.join(' ')} -a --force-exclusion`,
  './**/*.md': ['prettier --write'],
  './**/*.js': ['eslint --fix'],
  './**/*.jsx': ['eslint --fix']
};
