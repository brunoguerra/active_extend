#encoding: UTF-8

require "active_migration/transformer/grouped_field_fixed_spelling"

class SyscadBairrosTransformer < ActiveMigration::Transformer::GroupedFieldFixedSpelling
  
  include ActiveMigration::Transformer
  include ApplicationHelper
  
  def initialize(schema)
    super schema
    
    @domain_name = "bairros"
    @state_dictionary = ActiveMigration::Dictionary.new File.expand_path("../cache/estados_dictionary.yml", __FILE__)
    @city_dictionary = ActiveMigration::Dictionary.new File.expand_path("../cache/cidades_dictionary.yml", __FILE__)
  end

  def transform(row)
    super row
    
    # @TODO: insert state information
    #convert state entries
    #row[:state] = @state_dictionary.find row[:state]
    #row[:state] = State.find_by_name(row[:state])
    
    #delete state
    row.delete :state
    
    #convert state entries
    row[:city] = @city_dictionary.find row[:city].to_i.to_s
    row[:city] = City.where(name: row[:city]).first
    
    if row[:city].nil? and (!row[:city].nil? && !row[:city].empty?)
      raise "Não foi possível encontrar cidade. %s." % row[:city]
    end
    
    true
  end

    def end(schema_from, schema_to)
      super schema_from, schema_to
      Rails.logger.debug @group.to_yaml
    end
  
end