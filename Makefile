
#

build_subsites: build_help_subdir

build_help_subdir:
	cp favicon.ico __help/
	# Specify _subsite_config.yml first so that __help/_config.yml can override its settings
	bundle exec jekyll build --verbose --config "_subsite_config.yml,__help/_config.yml"


