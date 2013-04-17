require 'unit_test_helper.rb'
include ActsAsIndexed

class PreTokenizerTest < ActiveSupport::TestCase

  def test_strips_non_word_characters
    assert_equal "Chocolate Chip Cookies ", PreTokenizer.process("Chocolate-Chip Cookies!")
  end

  def test_strips_underscores
    assert_equal "Test try it", PreTokenizer.process("Test_try_it")
  end

end
