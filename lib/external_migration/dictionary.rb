
module ExternalMigration
  class Dictionary
    
    def initialize(url)
      @dictionary = YAML::load(File.open(url))
    end
    
    def find(term)
      if @dictionary.include? term.to_s
        @dictionary[term.to_s]
      else
        term.to_s
      end
    end
    
    
  end
end