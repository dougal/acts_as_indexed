module ActsAsIndexed
  class TokenNormalizer

    # Takes an array of tokens.
    # - Downcases the tokens when :normalize_case option is passed.
    # - Removes tokens of :min_token_length when option is passed.
    # Returns the resulting array of tokens.
    def self.process(arr, options={})
      if options[:normalize_case]
        arr = arr.map{ |t| t.downcase }
      end

      if options[:min_token_length]
        arr = arr.reject{ |w| w.size < options[:min_token_length] }
      end

      arr
    end

  end
end
