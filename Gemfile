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
  gem 'timecop'
  gem 'pry'
  gem 'test-unit'

  group :darwin do
    # OS X integration
    gem "ruby_gntp"
    gem "rb-fsevent"
  end
end
