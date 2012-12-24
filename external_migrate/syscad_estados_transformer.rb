
require "active_migration/transformer/grouped_field_fixed_spelling"

class SyscadEstadosTransformer < ActiveMigration::Transformer::GroupedFieldFixedSpelling
  
  include ActiveMigration::Transformer
  include ApplicationHelper
  
  def initialize(schema)
    super schema
    
    @domain_name = "estados"
  end
  
  def transform(row)
    res = super row
    row[:acronym] = row[:name]
    :ignore
  end
  
  def save_on_db
    class_to = schema_to_class
    
    @group.each do |key, row|
      if not State.where(acronym: row[:acronym]).exists?
        record = class_to.new(row)
        record.save!
      end
    end
  end
  
end