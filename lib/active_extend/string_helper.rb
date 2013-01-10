module StringHelper
  def name_or_empty(instance)
    instance ? instance.name.upcase : I18n.t('helpers.empty')
  end
  
  def name_or_nothing(instance)
    instance ? instance.name.upcase : ""
  end
end