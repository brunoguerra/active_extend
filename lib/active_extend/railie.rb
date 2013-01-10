require 'active_extend'
require 'rails'

module ActiveExtend
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.path_expand('../../tasks/active_extends_tasks.task'
    end
  end
end