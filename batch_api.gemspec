$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "batch_api/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "batch_api"
  s.version     = BatchApi::VERSION
  s.authors     = ["Alex Koppel"]
  s.email       = ["alex@alexkoppel.com"]
  s.homepage    = "http://github.com/arsduo/batch_api"
  s.summary     = "A RESTful Batch API for Rails"
  s.description = "A Batch API plugin that provides a RESTful syntax, allowing clients to make any " +
                  "number of REST calls with a single HTTP request."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "changelog.md", "readme.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_runtime_dependency("middleware")
  s.add_runtime_dependency("celluloid")
  
  s.add_development_dependency("rails", "~> 3.2")
  s.add_development_dependency("sinatra")
  s.add_development_dependency("rspec")
  s.add_development_dependency("rspec-rails")
  s.add_development_dependency("sqlite3")
  s.add_development_dependency("rack-contrib")
end
