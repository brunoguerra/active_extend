
module ActiveMigration
  module Transformer
    class GroupedFieldFixedSpelling
      
      include ActiveMigration::Transformer
      include ApplicationHelper
      
      attr_accessor :domain_name, :domain_dest
      
      def initialize(schema)
        @schema            = schema
        @field_group       = :name
        @field_group_fixed = :name_correct
        
        @group  = {}
        @rows   = []
        
        @domain_name = "domain"
      end
      
      def begin(schema_from, schema_to)
        @schema_from = schema_from
        @schema_to = schema_to
        @group = {}
        @domain_dictionary = {}
        @rows = []
      end
      
      def transform(row)
        begin
          #cache
          @rows << row
          
          fix_field row
          
          return :ignore if row[@field_group].nil?
          
          #validating and cleanup
          row[@field_group].gsub! /\s{2,}/, ' '
          row.delete @field_group_fixed
          
          @group[row[@field_group]] = row
          
          return :ignore
        rescue Exception => e  
          Rails.logger.debug "Error on transform. "+e.message+"\n"+e.backtrace.join("\n ")
          false
        end
      end
      
      def fix_field(row)
        #has name_correct?
        if (!row[@field_group_fixed].nil? && !row[@field_group_fixed].to_s.empty?)
          row[@field_group_fixed]               = row[@field_group_fixed].to_s.strip
          @domain_dictionary[row[@field_group]] = row[@field_group_fixed]
          row[@field_group]                     = row[@field_group_fixed]
        end
      end
    
      def end(schema_from, schema_to)
        save_on_cache
        save_on_db
      end
    
      def schema_to_class
        eval @schema_to[:url]
      end
    
      def save_on_db
    
        class_to = schema_to_class
    
        @group.each do |key, row|
          if not class_to.send(("find_by_%s" % @field_group).to_sym, row[@field_group])
            record = class_to.new(row)
            puts "SaveOnDB: "+row.to_yaml
            record.save!
          end
        end
      end
  
      def save_on_cache
    
        #cached path
        @cache_path = "db/external_migrate/cache/" 
        Dir.mkdir path if not Dir.exists? @cache_path
    
        puts_on_file @cache_path + "#{@domain_name}_dictionary.yml", @domain_dictionary.to_yaml
        #puts_on_file @cache_path + "#{@domain_name}_raw.csv", @rows.map { |i| i.values.join(",")}.join("\n")
        puts_on_file @cache_path + "#{@domain_name}_grouped.csv" do
          lines = []
          @group.each do |key, data|
            line = []
            data.each do |key, value|
              if value.is_a? String
                line << value
              elsif value.respond_to? :name
                line << value.name
              end
            end
            lines << line.join(",")
          end
          lines.join("\n")
        end
        #puts_on_file path + "#{@domain_name}.xml", @rows.to_xml
      end
    end
  end
end