
clientes:
  :type: :SCHEMA
  :from:
    :columns:
      :id: integer
      :name: string
      :name_sec: string
      :contacts_1_name: string
      :ignore1: :ignore!
      :ignore2: :ignore!
      :ignore3: :ignore!
      :ignore4: :ignore!
      :ignore5: :ignore! #9
      :address: string
      :district_name: string
      :city_name: string
      :state_name: string
      :phone: phone
      :fax: phone
      :cel_ADD_TO_NOTES: fone     
      :emails_email: string
      :doc: cnpj
      :doc_rg: cgf
      :customer_pj_total_employes: integer
      :annual_revenues: integer
      :ignore6: :ignore!
      :class: string
      :ignore7: :ignore!
      :is_customer: integer
      :ignore8: :ignore!
      :contacts_2_name: string
      :contacts_3_name: string
      :contacts_4_name: string
      :contacts_5_name: string
      :contacts_6_name: string
      :contacts_7_name: string
      
      :contacts_2_birthday: date
      :contacts_3_birthday: date
      :contacts_4_birthday: date
      :contacts_5_birthday: date
      :contacts_6_birthday: date
      :contacts_7_birthday: date
      
      :contacts_2_business_function: string
      :contacts_3_business_function: string
      :contacts_4_business_function: string
      :contacts_5_business_function: string
      :contacts_6_business_function: string
      :contacts_7_business_function: string
      
      :contacts_2_phone: string
      :contacts_3_phone: string
      :contacts_4_phone: string
      :contacts_5_phone: string
      :contacts_6_phone: string
      :contacts_7_phone: string
      
      :contacts_2_email: string
      :contacts_3_email: string
      :contacts_4_email: string
      :contacts_5_email: string
      :contacts_6_email: string
      :contacts_7_email: string
      
      :postal: string
      
      :site: string
      
      :ignore9: :ignore!
      
      :obs_ADD_TO_NOTES: string
      
    :format: :XLS
    :url: db/external_migrate/syscad/client_tests.xls
  :to:
    :format: :ACTIVE_RECORD
    :url: Customer
  :transformer: SyscadClientesTransformer