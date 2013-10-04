

module ExternalMigration
  
  #
  # Schema format:
  #
  # format: TXT_FIXED
  # url: text to read
  # ignore_lines: default 1
  # encoding: default 'windows-1251:utf-8'
  class TextFixed
    include ExternalMigration::Decoder
    
    attr_accessor :migration, :ignore_lines
    
    def initialize(schema)
      self.schema = schema
      @ignore_lines = schema[:ignore_lines] || 1
      @enconding = schema[:encoding] || 'windows-1251:utf-8'
    end
    
    def schema=(schema)
      
      if schema[:multiple_lines] == :true
        @schema_multiple_lines = true
        @schema_line_index = -1
        @schema = schema
        @schema_lines  = @schema[:columns].keys
        @schema[:lines] = @schema[:columns] #backup layout
        next_schema_line
      else
        @schema  = schema
      end
    end
    
    def migrate!
      puts "opening file #{@schema[:url]}"
      file = File.open(Rails.root.join(@schema[:url]), "r:#{@enconding}")
      file.each_line do |line|
        if @ignore_lines>0
          @ignore_lines -= 1
          next line
        end
        
        row = {}
        line_index = 0
        @schema[:columns].each do |column, column_prop|
          row[column.to_sym] = line[line_index..(line_index+column_prop[:length]-1)]
          row[column.to_sym].strip! if @schema[:strip_columns] == :true && !row[column.to_sym].nil?
          line_index += column_prop[:length]
        end
        row.keys.each {|k| row.delete k if k.to_s =~ /ignore\d+/ }
        @migration.migrate_row! row

        next_schema_line
      end
      file.close
      
    end

    def next_schema_line
      if @schema_multiple_lines
        @schema_line_index += 1
        @schema_line_index = 0 if @schema_line_index >= @schema_lines.size
        @schema[:columns] = @schema[:lines][@schema_lines[@schema_line_index]]
      end
    end
    
  end
  
end