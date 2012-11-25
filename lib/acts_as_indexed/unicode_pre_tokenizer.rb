begin
  require 'stringex'

rescue LoadError => e
  puts "=" * 40
  puts "stringex gem is not installed."
  puts "stringex gem is required by the UTF8 Tokenizer."
  puts "=" * 40

  raise e
end


# Converts Unicode characters to their ascii equivalent for indexing.
module ActsAsIndexed

  class UnicodePreTokenizer < PreTokenizer

    def self.process(unicode_str)
      ascii_str = Stringex::Unidecoder.decode(unicode_str)
      super(ascii_str)
    end

  end
end