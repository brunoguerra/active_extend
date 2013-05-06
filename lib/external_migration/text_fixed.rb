

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
      @schema = schema
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
      end
      file.close
      
    end
    
  end
  
end