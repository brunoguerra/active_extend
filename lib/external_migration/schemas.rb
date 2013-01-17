
module ExternalMigration
  
  module Schemas
    class ActiveMigartionSchemasError < StandardError; end
    
    ##
    # Façade class
    # make easy way to running batchs schemas migrations
    #
    # === File Format
    # name_migration:  
    #   :type: CUSTOM, SCHEMA 
    #   from: URL to from schema or Custom Param
    #   to: URL to destinate schema or Custom Param
    #   transformer: class will be called to data transformations
    class SchemasMigration
    
      attr_accessor :transformer, :schemas
    
      def initialize(file_schemas)
        raise "Invalid File: should not null!" if file_schemas.nil?
        raise "Invalid File: should not exists!" if not File.exists?(file_schemas)
        @schemas = YAML::load(File.open(file_schemas))
      end
      
      def migrate!
        ActiveRecord::Base.transaction do   
          @schemas.each do |key,schema|
            
            @migration_name = key
            @schema = schema
            
            msg = "Starting external migration: %s..." % @migration_name
            Rails.logger.info msg
            puts msg
            
            result = run_migration_job
            
            raise ActiveMigartionSchemasError.new("Failing Migrate Schemas: %s" % key) if not result
            
            msg = "Ending: %s." % @migration_name
            Rails.logger.info msg
            puts msg
          end
        end
      end
    
        def run_migration_job
          transformer_from_schema()

          case @schema[:type]
            when :SCHEMA
              self.migrate_schema
            when :CUSTOM
              self.migrate_custom
          end
        end

      def eval_class(class_str)
        begin
          class_found = eval class_str
          raise "its %s not a class" % class_str if !class_found.is_a?(Class) 
        rescue
          class_found = false
        end
      end

      def transformer_class=(class_str)
        
        path = class_str.split("::")
        
        
        path.map!(&:underscore)
        file_name = path.join("/") + ".rb"
      
        class_found = eval_class(class_str)
      
        if class_found==false
          require_dependence(file_name)
          class_found = eval_class(class_str)
          raise "[%s] Invald informed Transformer: %s.  Schema: %s" % [@migration_name, class_str, @schema.to_yaml] if class_found == false 
        end
      
        @transformer = (eval class_str).new @schema
      end
    
      def require_dependence(file_name)
      
        Rails.logger.warn "Requiring file %s" % file_name
      
        search_dependency(file_name).each do |file|
          if File.exists? file
            Rails.logger.debug "Including file %s" % file
            require file
            break
          end
        end
      end
    
      ##
      # @return Array with possible location of file
      def search_dependency(file_name)
        files = []
        files << Rails.root.join("db/external_migrate/" + file_name)
      
        #possibility paths
        unless File.exists?(files[0])
          Dir[file_name,
              File.expand_path("**/external_migrate/**/" + file_name),
              "../" + file_name,
              "../../" + file_name,
              File.expand_path("**/" + file_name)].each { |f| files << f }
        end
      
        files
      end
    
      def migrate_schema
        migration = ExternalMigration::Migration.new
        migration.name = @migration_name
        migration.schema_from = @schema[:from]
        migration.schema_to   = @schema[:to]
        migration.transformer = @transformer if not @transformer.nil?
        #rock!
        migration.migrate!
      end
    
      def migrate_custom
        raise "Transformer not assigned" if @transformer.nil?
        raise "Invalid Custom Migration Transformer" if not @transformer.respond_to?(:migrate!) 
      
        @transformer.migrate!
      end
    
      def transformer_from_schema
        if @schema.include? :transformer
          self.transformer_class = @schema[:transformer]
        else
          @transformer = nil
        end
      end
    
    
    end
  end
end