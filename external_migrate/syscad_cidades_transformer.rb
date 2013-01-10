
require "external_migration/transformer/grouped_field_fixed_spelling"
require "external_migration/dictionary"

class SyscadCidadesTransformer < ExternalMigration::Transformer::GroupedFieldFixedSpelling
  
  include ExternalMigration::Transformer
  include ApplicationHelper
  
  def initialize(schema)
    super schema
    
    @domain_name = "cidades"
    @state_dictionary = ExternalMigration::Dictionary.new File.expand_path("../cache/estados_dictionary.yml", __FILE__)
  end
  
  def transform(row)
    res = super row
    
    #convert state entries
    row[:state] = @state_dictionary.find row[:state]
    row[:state] = State.find_by_acronym(row[:state])
    
    #grouping and after save
    res
  end
  
  def end(schema_from, schema_to)
    super schema_from, schema_to
    Rails.logger.debug @group.to_yaml
  end
  
end