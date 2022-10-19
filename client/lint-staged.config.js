// lint-staged.config.js
module.exports = {
  '../{app,spec,config,lib}/**/*.{rb,erb,rake}': (files) =>
    `bundle exec rubocop ${files.join(' ')} -a --force-exclusion`,
  './**/*.{js,jsx}': ['eslint --fix'],
  './**/*.md': ['prettier --write'],
  './**/*.json': ['prettier --write'],
  './**/*.{yml,yaml}': ['prettier --write'],
  '*.scss': ['prettier --write']
};
