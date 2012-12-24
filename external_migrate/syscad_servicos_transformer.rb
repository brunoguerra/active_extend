class SyscadServicosTransformer
  
  include ActiveMigration::Transformer
  include ApplicationHelper
  
  def initialize(schema)
    super schema
    
    @domain_name = "servicos"
    
    #@last_id = TaskType.unscoped.select('max(id) as id').first.id.to_i
    #@last_id = 0 if @last_id.nil?
    
    @dictionary_servicos = {}
    
    @company_business_default = CompanyBusiness.first
  end
  
  def transform(row)
    puts row.to_yaml    
    row[:company_business] = @company_business_default    
    true
  end
  
  def after_row_saved(row, object)
    unless object.nil?
      @dictionary_servicos[row[:id].to_i.to_s] = object.id
    end
  end
  
  def end(schema_from, schema_to)
    puts_on_file Rails.root.join("db/external_migrate/cache/servicos_dictionary.yml") do
      @dictionary_servicos.to_yaml
    end
  end
  
end