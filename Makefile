
#

build_subsites: build_help_subdir

build_help_subdir:
	cp favicon.ico __help/
	bundle exec jekyll build --verbose --config __help/_config.yml


