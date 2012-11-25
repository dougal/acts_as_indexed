module ActsAsIndexed
  class Tokenizer

    # Takes a string of space-separated tokens, returns an array of those tokens.
    def self.process(str)
      str.split
    end

  end
end
