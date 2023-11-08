Command to generate a new rails application:
`rails new <APP NAME> --api -M -d postgresql`

`--api`  will specify that the application is to be used for backend purposes only and Rails will not generate any frontend views.
`-M` tells Rails to skip the generation of Action Mailer and Action Mailbox files
`-d` will specify the DBMS for the application. In this example, we are using postgresql

Additional Gems:

`gem install pry-rails rspec byebug`
`rails generate rspec:install`