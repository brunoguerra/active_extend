
require "active_migration/transformer/grouped_field_fixed_spelling"
require "active_migration/dictionary"
require "active_migration/converters/rtf_to_html"

class SyscadAtividadesTransformer
  
  include ActiveMigration::Transformer
  include ApplicationHelper
  
  def initialize(schema)
    super schema
    
    @domain_name = "atividades"
    @segmentos_dictionary = ActiveMigration::Dictionary.new File.expand_path("../cache/segmentos_dictionary.yml", __FILE__)
    
    @atividades_dictionary = {}
  end
  
  def transform(row)    
    #convert state entries
    row[:business_segment] = @segmentos_dictionary.find(row[:business_segment].to_i.to_s).to_s
    row[:business_segment] = BusinessSegment.find_by_id(row[:business_segment]) if (!row[:business_segment].nil? &&  !row[:business_segment].empty?)
    row.delete :business_segment unless row[:business_segment].is_a? BusinessSegment
    transform_notes row
    true
  end
  
  def transform_notes(row)
    if !row[:notes].nil? && !row[:notes].empty?
      row[:notes] = ActiveMigration::Converters::RtfToHtml.new.parse(row[:notes]).encode(Encoding::US_ASCII, :invalid => :replace, :undef => :replace, :replace => '')
    end
  end
  
  def after_row_saved(row, object)
    unless object.nil?
      @atividades_dictionary[row[:id].to_i.to_s] = object.id
    end
  end
  
  def end(schema_from, schema_to)
    super schema_from, schema_to
    puts_on_file Rails.root.join("db/external_migrate/cache/atividades_dictionary.yml") do
      @atividades_dictionary.to_yaml
    end
  end
  
end