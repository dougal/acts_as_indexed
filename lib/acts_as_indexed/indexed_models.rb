class IndexedModels
  cattr_reader :registered_models
  
  def self.with_query(query, options={})
    @@registered_models ||= []
    self.load_all_models! if @@registered_models.empty? # Sometimes models haven't been loaded if the server has just restarted
    included_models = @@registered_models.clone
    included_models.delete_if{|m| [options[:except]].flatten.map{|s|class_for_sym(s)}.include? m} if options[:except]
    included_models.delete_if{|m| ![options[:only]].flatten.map{|s|class_for_sym(s)}.include? m} if options[:only]
    results = included_models.collect do |model|
      model.send :with_query, query
    end
    results.delete([])
    return results
  end

  def self.register_model(model)
    @@registered_models ||= []
    @@registered_models << model unless @@registered_models.include? model

    self.load_all_models!
  end

  def self.load_all_models!
    return if defined? @@models_loaded
    @@models_loaded = true
    module_dir = File.join Rails.root, 'app', 'models', '*'
    module_files = Dir.glob module_dir
    module_files.each do |filename|
      require filename
    end
  end

  private
    def self.class_for_sym(symbol)
      Object.const_get(symbol.to_s.classify) \
        rescue Object.const_get(symbol.to_s.singularize.classify) \
        rescue raise "No such class #{symbol.to_s.classify}"
    end
end
