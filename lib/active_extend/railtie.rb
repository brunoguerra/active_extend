require 'active_extend'
require 'rails'

module ActiveExtend
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../../tasks/external_migrate.rake', __FILE__)
    end
  end
end