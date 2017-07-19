export RAILS_ENV="test"
export CHROME_ARGS="--no-sandbox"
export CHROME_BIN="chromium-browser"

#rake db:create
#rake db:schema:load
Xvfb +extension RANDR :99 -screen 0 1600x900x16 &

#rake lint
#rake security
rake spec

rake ci:verify_code_coverage
rake konacha:run
