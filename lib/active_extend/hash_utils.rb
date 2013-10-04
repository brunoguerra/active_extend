Hash.class_eval do
  def self.keys_to_sym(h_or_v)
    Hash === h_or_v ? 
      Hash[
        h_or_v.map do |k, v| 
          [k.respond_to?(:to_sym) ? k.to_sym : k, Hash.keys_to_sym(v)] 
        end 
      ] : h_or_v
  end

  def keys_to_sym
    Hash.keys_to_sym self
  end
end