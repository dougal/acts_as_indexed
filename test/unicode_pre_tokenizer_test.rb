# encoding: UTF-8

require 'abstract_unit'
include ActsAsIndexed

require 'acts_as_indexed/unicode_pre_tokenizer'

class UnicodePreTokenizerTest < ActiveSupport::TestCase

  def test_strips_non_word_characters
    assert_equal "Chocolate Chip Cookies ", UnicodePreTokenizer.process("Chocolate-Chip Cookies!")
  end

  def test_converts_unicode_to_ascii_and_strips_non_word_characters
    assert_equal "Shchukinskaia", UnicodePreTokenizer.process("Щукинская")
    assert_equal "shchukinskaia", UnicodePreTokenizer.process("щукинская")
    assert_equal " n qdr  l   kl lzjj w hdh l yw lmn", UnicodePreTokenizer.process("أنا قادر على أكل الزجاج و هذا لا يؤلمن")
  end

end
