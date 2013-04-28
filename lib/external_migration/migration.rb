
require 'active_support'

module ExternalMigration
  class ActiveMigartionError < StandardError; end
  class ActiveMigartionDataSourceError < ActiveMigartionError; end  
  class AciteMigrationInvalidRecordError < ActiveMigartionError; end  
  
  
  class Schema
    ##
    # @attr columns Hash with name and type
    # @attr format Describe data format
    # @attr url define path or object schema
    attr_accessor :columns, :format, :url
    
  end
  
  ##
  # Module Data Transformation
  # When passing schema file or struct, the data between datasources
  # needs a transformations 
  module Transformer
    ##
    # called on start of migration
    def begin(schema_from, schema_to)
      # nothing      
    end
    
    ##
    # called on start of transaction
    def begin_transaction(schema_from, schema_to)
      # nothing
    end
    
    ##
    # transform from data row to destinate data row 
    # @result true, false or :ignore to ignore this row
    def transform(row)
      raise "Implements transform method!"
    end
    
    ##
    # called on ending migration
    def end(schema_from, schema_to)
      # nothing
    end
    
    ##
    # called on ending transaction
    def end_transaction(schema_from, schema_to)
      # nothing
    end
    
    ##
    #
    def after_row_saved(row, object)
      #
    end
    
    def transform_ignore_fields(row)
      #delete ignore
      row.reject! { |key,value| key.to_s.start_with?("ignore") }
    end
    
  end  
  
  module Decoder
    def migrate!
    end
  end
  
  ##
  # == Class Migration
  # 
  # Migrate data between  data source and transforme to destination 
  #
  class Migration
    attr_accessor :schema_from, :schema_to, :transformer, :name
  
    # constructor
    def initialize(schema_url=nil)
      self.load_schema(schema_url) unless schema_url.nil?
    end
    
    ##
    # load yml schemas from and to
    def load_schema(url)
      schema = YAML::load(File.open(url))
      puts "loading #{schema[:from].to_yaml}"
      self.schema_from = schema[:from]
      self.schema_to = schema[:to]
    end
    
    
    ##
    # Running migration from configured files
    # 
    # ps> Default Behaviour Ignore First line - assumes head line
    
    def migrate!
    
      raise "schema_from needs" if @schema_from.nil?
      raise "schema_to needs" if @schema_to.nil?
      
      res = @transformer.begin_transaction(@schema_from, @schema_to) unless @transformer.nil?
      
      ActiveRecord::Base.transaction do      
        begin_migration()
    
        # TODO: Make flexible configurable and more input formats
        if @schema_from[:format].to_s.to_sym == :XLS
          xls_migrate()
        elsif @schema_from[:format].to_s.to_sym == :TXT_FIXED
          decoder = TextFixed.new(@schema_from)
          decoder.migration = self
          decoder.migrate!
        end
      
        end_migration()
      end
      
      res = @transformer.end_transaction(@schema_from, @schema_to) unless @transformer.nil?
      
      return true
    end
    
    def migreate_row!(row_to)
      begin
          #transform row to @schema_to
          res = true
          res = @transformer.transform(row_to) unless @transformer.nil?
          
          if (res!=:ignore)
            res = res==true && send_row_to_schema(row_to)
            raise_migration if (res==false)
            
            @transformer.after_row_saved(row_to, @last_object) unless @transformer.nil?
          end
          
          @line+=1
        end
      rescue Exception => e
        line = @line.nil? ? 0 : @line
        column = @column.nil? ? 0 : @column
        
        obj = @last_object || (e.respond_to?(:record) && (e.record)) || nil
        
        if !obj.nil?
          raise ActiveMigartionDataSourceError.new obj.errors.to_yaml.to_s.concat("Failing import excel source format from %s. %d:%d [ignored head]. " % [@schema_from[:url], column, line]).concat(e.message).concat("\n----"+e.backtrace.to_yaml)         
        else
          raise ActiveMigartionDataSourceError.new ("Failing import excel source format from %s. %d:%d [ignored head]. " % [@schema_from[:url], column, line]).concat(e.message).concat("\n----"+e.backtrace.to_yaml)
        end
      end

    end
    
    
    def xls_migrate
      begin
        @xls = Spreadsheet.open @schema_from[:url]
        # TODO: make others workbook accessible by configuration
        sheet = @xls.worksheet 0
    
        @line = 0
    
        # ignore head line
        sheet.each 1 do |row|
          @column = 0
          row_to = { }
          
          #read schema columns and types
          @schema_from[:columns].each do |schema_column, schema_type|
            row_to.merge!(schema_column.to_sym => row[@column])
            @column+=1
          end
          
          self.migrate_row! row_to
          @line+=1
        end
      rescue Exception => e
        line = @line.nil? ? 0 : @line
        column = @column.nil? ? 0 : @column
        
        obj = @last_object || (e.respond_to?(:record) && (e.record)) || nil
        
        if !obj.nil?
          raise ActiveMigartionDataSourceError.new obj.errors.to_yaml.to_s.concat("Failing import excel source format from %s. %d:%d [ignored head]. " % [@schema_from[:url], column, line]).concat(e.message).concat("\n----"+e.backtrace.to_yaml)         
        else
          raise ActiveMigartionDataSourceError.new ("Failing import excel source format from %s. %d:%d [ignored head]. " % [@schema_from[:url], column, line]).concat(e.message).concat("\n----"+e.backtrace.to_yaml)
        end
      end
    end
    
    
    def begin_migration
      # TODO: make transactional
      res = @transformer.begin(@schema_from, @schema_to) unless @transformer.nil?
    end
    
    
    def end_migration
      res = @transformer.end(@schema_from, @schema_to) unless @transformer.nil?
    end
    
    def raise_migration
      raise "failing migration %s.  Line: %d, Column: %d" % [@name, @line, @column]
    end
  
    def send_row_to_schema(row)
      
      if @schema_to[:format].to_sym == :ACTIVE_RECORD
        
        # TODO: optimize on initialize migration
        class_schema_to = eval @schema_to[:url]
        
        @last_object = class_schema_to.new(row)
        res = @last_object.save
      
        if (!res)
          msg = "[Schema:%s] Error on send to ACTIVE_RECORD %s. \n%s \nrow: \n%s" % [@name, @schema_to[:url], @last_object.errors.to_yaml, row.to_yaml]
          Rails.logger.error msg
          raise AciteMigrationInvalidRecordError.new msg
        end
      
        return res
      
      else
        raise "Not valid schema::TO format! %s" % @name  
      end
    end
    
    ##
    # loads yml file and convert to hash on schema_from
    # @deprecated
    def load_schema_from(url)
      self.schema_from = YAML::load(File.open(url))
    end
    
    ##
    # load yml file and convert to hash on schema_to
    # @deprecated
    def load_schema_to(url)
      self.schema_to = YAML::load(File.open(url))      
    end
    
  end
  
end