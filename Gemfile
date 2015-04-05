source "http://rubygems.org"

# Declare your gem's dependencies in batch_api.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

group :development, :test do
  # Testing infrastructure
  gem 'guard'
  gem 'guard-rspec'
  gem 'faker'
  gem 'test-unit'
  gem 'timecop'
  gem 'debugger', :platforms => [:mri_19]
  gem 'byebug', :platforms => [:mri_20, :mri_21]
  gem 'pry'

  # testing the request infrastructure
  gem "rails", "~> 4.2"
  gem "sinatra"
  gem "rspec"
  gem "rspec-rails"
  gem "rack-contrib"
  # for CRuby, Rubinius, including Windows and RubyInstaller
  gem "sqlite3", :platform => [:ruby, :mswin, :mingw]
  # for JRuby
  gem "jdbc-sqlite3", :platform => :jruby

  group :darwin do
    # OS X integration
    gem "ruby_gntp"
    gem "rb-fsevent"
  end
end
