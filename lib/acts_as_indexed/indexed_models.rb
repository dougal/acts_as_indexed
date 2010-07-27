class IndexedModels
  def self.registered_models
    self.load_all_models!
    @@registered_models
  end
  
  def self.with_query(query, options={})
    self.load_all_models! # Sometimes models haven't been loaded if the server has just restarted
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
    @@registered_models ||= []
    module_dir = File.join Rails.root, 'app', 'models', '*'
    load_models(module_dir)
  end

  private
    def self.class_for_sym(symbol)
      Object.const_get(symbol.to_s.classify) \
        rescue Object.const_get(symbol.to_s.singularize.classify) \
        rescue raise "No such class #{symbol.to_s.classify}"
    end

    def self.load_models(directory)
      module_files = Dir.glob directory
      module_files.each do |filename|
        if File.directory? filename
          load_models(filename + "/*")
        else
          require filename
        end
      end
    end

end
