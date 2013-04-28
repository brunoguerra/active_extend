

module ExternalMigrate
  
  class TextFixed
    include ExternalMigration::Decoder
    
    attr_accessor :migration, :ignore_lines
    
    def initialize(schema)
      self.schema = schema
      @ignore_lines = 1
    end
    
    def schema=(schema)
      @schema = schema
    end
    
    def migrate!
      puts "opening file #{@schema.url}"
      file = File.open(@schema.url, 'r:urf-8')
      line_index = 0
      file.each_line do |line|
        row = {}
        @schema[:columns].each do |column, column_prop|
          row[column.to_sym] = line[line_index..(line_index+column_prop[:length])]
          line_index += column_prop[:length]
        end
        @migration.migreate_row! row
      end
      file.close
      
    end
    
  end
  
end