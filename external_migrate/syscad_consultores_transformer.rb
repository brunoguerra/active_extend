class SyscadConsultoresTransformer
  
  include ActiveMigration::Transformer
  include ApplicationHelper
  
  def initialize(schema)
    super schema
    
    @domain_name = "consultores"
    
    @last_id = User.unscoped.select('max(id) as max_id').first.max_id.to_i
    @last_id = 0 if @last_id.nil?
    
    @dictionary_consultores = {}
    
    @company_business_default = CompanyBusiness.first
  end
  
  def transform(row)
    puts row.to_yaml    
    row[:name] += " CMGB" if row[:name].count(" ")==0
    row[:email] = row[:name].downcase.gsub(/\s/, "")+"@cmgb.com.br"
    row[:password] = "cmgbconsultor"
    row[:password_confirmation] = "cmgbconsultor"
    
    row[:primary_company_business] = @company_business_default
    
    row[:type_id] = UserType.SELLER
    
    #dictionary
    @last_id += 1
    true
  end
  
  def after_row_saved(row, object)
    unless object.nil?
      @dictionary_consultores[row[:id].to_i.to_s] = object.id
    end
  end
  
  def end(schema_from, schema_to)
    puts_on_file Rails.root.join("db/external_migrate/cache/consultores_dictionary.yml") do
      @dictionary_consultores.to_yaml
    end
  end
  
end