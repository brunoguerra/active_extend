$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "active_extend/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "active_extend"
  s.version     = ActiveExtend::VERSION.dup
  s.authors     = ["Bruno Guerra"]
  s.email       = ["bruno@woese.com"]
  s.homepage    = "http://www.woese.com"
  s.summary     = "many cool behaviors for active_model"
  s.description = "many cool behaviors for active_model."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]
  s.require_paths = ["lib"]

  s.add_dependency "rails", "~> 3.2.9"

  s.add_dependency "spreadsheet"
end
