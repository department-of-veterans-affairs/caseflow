# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')
Rails.application.config.assets.paths << Rails.root.join('client', 'node_modules')

# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets 
# folder are already added.
Rails.application.config.assets.precompile += %w( explain-appeal-timeline.js )
Rails.application.config.assets.precompile += %w( explain-appeal-network.js )
Rails.application.config.assets.precompile += %w( stats.js )
Rails.application.config.assets.precompile += %w( task-tree.js )
Rails.application.config.assets.precompile += %w( pdf.worker.js )

Rails.application.config.assets.precompile += %w( webpack-bundle.js )
Rails.application.config.assets.precompile += %w( 0.webpack-bundle.js )

# Precompile print stylesheets.
Rails.application.config.assets.precompile += %w( print/hearings_worksheet.css )
Rails.application.config.assets.precompile += %w( print/hearings_worksheet_overrides.css )
Rails.application.config.assets.precompile += %w( print/hearings_schedule.css )
Rails.application.config.assets.precompile += %w( explain_appeal.css )
Rails.application.config.assets.precompile += %w( explain_appeal_timeline.css )

Rails.application.config.assets.precompile += %w( favicon.ico )
Rails.application.config.assets.precompile << %w( *.woff *.woff2 *.eot *.ttf )
# Add client/assets/ folders to asset pipeline's search path.
# If you do not want to move existing images and fonts from your Rails app
# you could also consider creating symlinks there that point to the original
# rails directories. In that case, you would not add these paths here.
# If you have a different server bundle file than your client bundle, you'll
# need to add it here, like this:
# Rails.application.config.assets.precompile += %w( server-bundle.js )
