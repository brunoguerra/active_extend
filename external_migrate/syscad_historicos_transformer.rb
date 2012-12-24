
require "active_migration/dictionary"

class SyscadHistoricosTransformer
  
  include ActiveMigration::Transformer
  include ApplicationHelper
  
  def initialize(schema)
    super schema
    
    @domain_name = "historico"
    
    @servicos_dictionary = ActiveMigration::Dictionary.new File.expand_path("../cache/servicos_dictionary.yml", __FILE__)
    @consultores_dictionary = ActiveMigration::Dictionary.new File.expand_path("../cache/consultores_dictionary.yml", __FILE__)
    
    @user_default = User.first
  end
  
  
  def transform(row)
    row[:type_id]       = @servicos_dictionary.find(row[:type_id].to_i.to_s)
    row[:type]          = TaskType.find_by_id(row[:type_id])
    row[:name] = "Syscad: "+(row[:type].nil? || row[:type].name).to_s
    
    row[:due_time]      = Time.now.to_s                 if row[:due_time].nil?
    
    row[:finish_time]   = row[:due_time]                if row[:finish_time].nil?
    row[:status]        = SystemTaskStatus.CLOSED
    row[:resolution]    = SystemTaskResolution.RESOLVED
    row[:user]          = @user_default
    
    row[:notes]         = "Importado: "+Time.now.strftime("%d/%m/%Y %H:%m") if row[:notes].nil? || row[:notes].empty?
    
    row[:interested]    = Customer.find_by_external_key(row[:interested])
    row[:assigned]      = User.find_by_id(@consultores_dictionary.find(row[:assigned].to_i.to_s)) unless row[:assigned].nil?
    
    transform_ignore_fields row
    
    true
  end
  
  
  
end