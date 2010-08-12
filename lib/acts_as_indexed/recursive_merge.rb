class Hash
  def recursive_merge!(h)
    self.merge!(h) do |key, _old, _new|
      if _old.is_a? Hash
        _old.recursive_merge!(_new)
      elsif _old.is_a? Array
        _old + _new
      else
        _new
      end
    end
  end
end
