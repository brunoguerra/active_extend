#!/bin/env ruby
# encoding: utf-8

require "active_migration/transformer/grouped_field_fixed_spelling"
require "active_migration/dictionary"
require "active_migration/spelling_fix"

class SyscadClientesTransformer
  
  include ActiveMigration::Transformer
  include ApplicationHelper
  
  def initialize(schema)
    super schema
    
    @domain_name = "clientes"
    
    @district_dictionary = ActiveMigration::Dictionary.new File.expand_path("../cache/bairros_dictionary.yml", __FILE__)
    @state_dictionary = ActiveMigration::Dictionary.new File.expand_path("../cache/estados_dictionary.yml", __FILE__)
    @city_dictionary = ActiveMigration::Dictionary.new File.expand_path("../cache/cidades_dictionary.yml", __FILE__)
    
    @emails_fixer = ActiveMigration::SpellingFix.new File.expand_path("../cache/emails_rules.yml", __FILE__)
    
    @ignore_record_error = true
  end
  
  def transform(row)
    row[:notes] = '' if row[:notes].nil?
    
    transform_customer_pj row
    transform_contacts row
    transform_customer row
    transform_ignore_fields row
    
    begin
      create_customer row
    rescue
      if @ignore_record_error
        Rails.logger.error "== Error:\n\n".concat(message_record_error())
      end
    end
    :ignore
  end
  
  def transform_customer(row)
    #name is empty?
    if (row[:name].nil? || row[:name].empty?) && ((!row[:name_sec].nil?) && (!row[:name_sec].empty?))
      row[:name] = row[:name_sec]
    end
    
    validate_cnpj row
    
    #
    unless row[:cel_ADD_TO_NOTES].nil?
      row[:notes].concat("\nCelular: "+row.delete(:cel_ADD_TO_NOTES))
    else
      row.delete :cel_ADD_TO_NOTES
    end
    
    unless row[:obs_ADD_TO_NOTES].nil?    
      row[:notes].concat("\n"+row.delete(:obs_ADD_TO_NOTES))
    else
      row.delete :obs_ADD_TO_NOTES
    end
    
    #convert state entries
    row[:state]     = State.find_by_acronym(@state_dictionary.find(row.delete(:state_name).to_s))
    
    #convert city entries
    city = @city_dictionary.find(row.delete(:city_name))
    row[:city]      = City.where(name: city, state_id: nil_or_id(row[:state])).first
    
    #convert district entries
    district        = @district_dictionary.find(row.delete(:district_name))
    row[:district]  = District.where(name: district, city_id: nil_or_id(row[:city])).first
    
    #email
    email = @emails_fixer.fix!(row.delete :emails_email)
    row[:emails] = [{:email => email}] unless email.nil?
  end
  
  def validate_cnpj(row)
    row[:doc] = '' if row[:doc].nil?
    row[:doc] = row[:doc].gsub(/[\.,\-\/\\\'\"\s;–\~\%]/, '')
    
    if (((row[:doc] != "") &&
         (row[:doc] != '0'*14)) &&
        (!Cnpj.new(row[:doc]).valido?))
      row[:notes].concat("CNPJ Inv: %s" % row[:doc])
      
      row[:name] = row[:name].to_s.concat("(CNPJ Inv)" % row[:doc])
      
      row[:doc] = ""
    end
  end
  
  def transform_contacts(row)
    row[:contacts] = []
    1..8.times do |n|
      unless (row[("contacts_%d_name" % n).to_sym].nil? && row[("contacts_%d_name" % n).to_sym].nil?)
        contact = {}
        contact[:name]              = row[("contacts_%d_name" % n).to_sym]
        contact[:phone]             = row[("contacts_%d_phone" % n).to_sym]
        contact[:cell]              = row[("contacts_%d_cell" % n).to_sym]
        contact[:business_function] = row[("contacts_%d_business_function" % n).to_sym]
        contact[:birthday]          = row[("contacts_%d_birthday" % n).to_sym]
        
        contact[:emails] = []
        contact[:emails] << { email: @emails_fixer.fix!(row[("contacts_%d_email" % n).to_sym]) } unless row[("contacts_%d_email" % n).to_sym].nil?
        
        row[:contacts] << contact
      end
      
      row.delete ("contacts_%d_name" % n).to_sym   
      row.delete ("contacts_%d_phone" % n).to_sym
      row.delete ("contacts_%d_cell" % n).to_sym
      row.delete ("contacts_%d_email" % n).to_sym
      row.delete ("contacts_%d_business_function" % n).to_sym
      row.delete ("contacts_%d_birthday" % n).to_sym
    end
  end
  
  def transform_customer_pj(row)
    row[:customer_pj] = {}
    
    #segment
    segment = row.delete :segment
    row[:customer_pj][:segments] = []
    row[:customer_pj][:segments] << BusinessSegment.find(segment) if (!segment.nil? && !segment.empty?)
    
    #segment
    segment = row.delete :activity
    row[:customer_pj][:activities] = []
    row[:customer_pj][:activities] << BusinessActivity.find(row[:activity]) if (!row[:activity].nil? && !row[:activity].empty?)
    
    #
    row[:customer_pj][:annual_revenues] = row.delete :annual_revenues
    class_str = row.delete :class
    row[:notes].concat("Classe: "+class_str+"\n") unless class_str.nil?
    row[:is_customer] = (row[:is_customer].to_i == 1)
    
    #total_employes
    total_employes = row.delete :customer_pj_total_employes
    row[:customer_pj][:total_employes] = total_employes
    
    row[:customer_pj][:fax] = row.delete :fax
    
  end
  
  def nil_or_id obj
    if obj.nil?
      nil
    else
      obj.id
    end
  end
  
  def disduplicate!(row)
    if (!row[:doc].nil?) && (!row[:doc].empty?) && (Customer.where(doc: row[:doc]).count>0)
      row[:name].concat("(CNPJ Dup %d)" % Customer.where(doc: row[:doc]).count)
      row[:notes] = '' if row[:notes].nil?
      row[:notes].concat("\nCNPJ Duplicado: %s" % row[:doc])
      row[:doc] = ''
    end
    
    if Customer.where(name: row[:name]).count>0
      row[:name].concat("(NOME Dup %d)" % Customer.where(name: row[:name]).count)
      row[:notes] = "" if row[:notes].nil?
      row[:notes].concat("\nNOME Duplicado: %s" % row[:name])
    end
  end
  
  def create_customer(row)
    
    disduplicate! row
    
    Customer.transaction do
    
      #customer_pj = row[:customer_pj]
      #contacts    = row[:contacts]
      #segments    = row[:segments]
      #activities  = row[:activities]
    
      customer_pj = row.delete :customer_pj
      contacts    = row.delete :contacts
      emails      = row.delete :emails
    
      #segments    = row.delete :segments
      #activities  = row.delete :activities
    
      @customer   = Customer.new(row)
      @person     = CustomerPj.new(customer_pj)
      @customer.person   = @person
    
      #complete valid? 
      @customer.complete = true
      @customer.complete = @customer.valid?
        
      #still valid?
      @customer.complete &&= @customer.valid?
    
      unless @customer.save  
        raise_invalid_customer
      else
        #@person.activities = activities   if activities.count>0
        #@person.segments   = segments     if segments.count>0
        #
        contacts.each do |contact_hash|
          emails = contact_hash.delete :emails
        
          contact = @customer.contacts.build contact_hash
          raise_invalid_customer unless @customer.save
        
          emails.each do |email_hash|
            contact.emails.build email_hash
          end
          raise_invalid_customer unless contact.save
        end
      
        raise_invalid_customer unless @customer.valid?
      end
    end
    true
  end
  
  def message_record_error
     message = ""

      if @customer.errors.messages.include? :contacts
        @customer.contacts.each do |contact|
          unless contact.valid?
            message += "Contato: #{contact.name} #{contact.errors.to_yaml}\n"
          end
        end
      end

      "Error ao salvar registro. %s\n%s" % [@customer.errors.to_yaml,
                                                                        message]    
  end
  
  def raise_invalid_customer    
    raise StandardError.new message_record_error
  end
  
  def end(schema_from, schema_to)
    super schema_from, schema_to
  end
  
end