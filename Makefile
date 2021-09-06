
#

build_subsites: build_help_subdir

build_help_subdir:
	bundle exec jekyll build --verbose --config __help/_config.yml


