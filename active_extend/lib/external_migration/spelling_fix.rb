
module ExternalMigration
  class SpellingFix
    
    def initialize(url)
      @rules = YAML::load(File.open(url))
    end
    
    def fix!(term)
      return term if term.nil? || term.empty?
      @rules.each do |before,after|
        term.gsub! before, after
      end
      
      term
    end
    
    
  end
end