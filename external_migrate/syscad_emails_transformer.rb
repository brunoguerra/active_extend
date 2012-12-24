
class SyscadEmailsTransformer
  
  include ActiveMigration::Transformer
  include ApplicationHelper
  
  def initialize(schema)
    super schema
    
    @domain_name = "emails"
    @emails_rules = {}
  end
  
  def transform(row)
    @emails_rules[row[:before].to_s] = row[:after]
    :ignore
  end
  
  def end(schema_from, schema_to)
    super schema_from, schema_to
    puts_on_file Rails.root.join("db/external_migrate/cache/emails_rules.yml") do
      @emails_rules.to_yaml
    end
  end
  
end