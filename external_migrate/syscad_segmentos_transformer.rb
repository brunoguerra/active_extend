
require "active_migration/transformer/grouped_field_fixed_spelling"
require "active_migration/dictionary"

class SyscadSegmentosTransformer
  
  include ActiveMigration::Transformer
  include ApplicationHelper
  
  def initialize(schema)
    super schema
    
    @domain_name = "segmentos"
    @segmentos_dictionary = {}
  end
  
  def transform(row)        
    true
  end
  
  def after_row_saved(row, object)
    unless object.nil?
      @segmentos_dictionary[row[:id].to_i.to_s] = object.id
    end
  end
  
  def end(schema_from, schema_to)
    super schema_from, schema_to
    puts_on_file Rails.root.join("db/external_migrate/cache/segmentos_dictionary.yml") do
      @segmentos_dictionary.to_yaml
    end
  end
  
end