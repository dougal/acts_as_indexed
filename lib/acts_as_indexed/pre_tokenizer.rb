module ActsAsIndexed
  class PreTokenizer

    # Strips all non-word characters and returns the resulting
    # string.
    def self.process(str)
      str.gsub(/[\W_]/,' ')
    end

  end
end
