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

  group :darwin do
    # OS X integration
    gem "ruby_gntp"
    gem "rb-fsevent"
  end
end
