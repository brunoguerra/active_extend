
require 'devise/orm/active_record'

module ActiveDisablable
  
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:default_scope) { base.where(:enabled => true) }
  end
  
  module ClassMethods
    def all_include_disabled
      unscoped
    end
    
    def all_disabled
      where(:enabled => false)
    end
    
  end
  
  
  
  def disable
    self.enabled = false
  end
  
  def enable
    self.enabled = true
  end
  
  def enabled?
    self.enabled
  end
  
  def disabled?
    !self.enabled
  end  
  
  def destroy
    if (@destroy_fully || self.disabled?)
      super
    else
      disable
      self.save
    end
  end
  
  def recovery
    enable
    self.save
  end
  
  def destroy_fully
    @destroy_fully = true
    self.destroy
  end
    
end