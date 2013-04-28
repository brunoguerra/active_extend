namespace :db do
  task external_migrate: :environment do    
    require "external_migration"
    
    Dir[Rails.root.join("db/external_migrate/*schemas.yml")].each do |file|
      @migration_schemas = ExternalMigration::Schemas::SchemasMigration.new file
      if @migration_schemas.migrate!
        Rails.logger.info "Migration success! %s" % file
      end
    end
  end
end