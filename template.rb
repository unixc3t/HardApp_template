# frozen_string_literal: true

def source_paths
  [__dir__]
end

def add_gems
  gem 'devise', '~> 4.7', '>= 4.7.1'
  gem 'friendly_id', '~> 5.3'
  gem 'sidekiq', '~> 6.0', '>= 6.0.1'
end

def add_users
  # Install Devise
  generate 'devise:install'

  # Configure Devise
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'

  route "root to: 'home#index'"

  # Create Devise User
  generate :devise, 'User', 'username', 'name', 'admin:boolean'

  # set admin boolean to false by default
  in_root do
    migration = Dir.glob('db/migrate/*').max_by { |f| File.mtime(f) }
    gsub_file migration, /:admin/, ':admin, default: false'
  end
end

def remove_app_css
  remove_file 'app/assets/stylesheets/application.css'
end

def copy_templates
  directory 'app', force: true
end

def add_bulma
  run 'yarn add bulma'
end

def add_fontawesome
  run 'yarn add @fortawesome/fontawesome-free'
  inject_into_file('app/javascript/packs/application.js',
                   "import '../../../node_modules/@fortawesome/fontawesome-free/css/all.min.css';",
                 before: "require('@rails/ujs').start();")
  append_to_file('app/javascript/packs/application.js',"require('./menu.js');")
end

def add_autoprefixer
  run 'yarn add autoprefixer'
end

def add_tailwind
  run 'yarn add tailwindcss'
  run 'node_modules/.bin/tailwind init'
  run 'mkdir app/javascript/stylesheets'
 append_to_file('app/javascript/packs/application.js', 'import "../stylesheets/application"')
  inject_into_file('./postcss.config.js',
                   "require('tailwindcss'),\n", after: 'plugins: [')
end

def add_sidekiq
  environment 'config.active_job.queue_adapter = :sidekiq'

  insert_into_file 'config/routes.rb',
                   "require 'sidekiq/web'\n\n",
                   before: 'Rails.application.routes.draw do'

  content = <<-RUBY
    authenticate :user, lambda { |u| u.admin? } do
      mount Sidekiq::Web => '/sidekiq'
    end
  RUBY
  insert_into_file 'config/routes.rb', "#{content}\n\n", after: "Rails.application.routes.draw do\n"
end

def add_friendly_id
  generate "friendly_id"
end

source_paths

add_gems

after_bundle do
  add_users
  remove_app_css
  add_sidekiq
  copy_templates
  add_bulma
  add_fontawesome
  add_tailwind
  add_autoprefixer
  add_friendly_id

  # Migrate
  rails_command 'db:create'
  rails_command 'db:migrate'

  git :init
  git add: '.'
  git commit: %( -m "Initial commit" )

  say
  say 'hard app successfully created! 👍', :green
  say
  say 'Switch to your app by running:'
  say "$ cd #{app_name}", :yellow
  say
  say 'Then run:'
  say '$ rails server', :green
end
