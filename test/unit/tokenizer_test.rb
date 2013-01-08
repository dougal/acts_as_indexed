require 'unit_test_helper.rb'
include ActsAsIndexed

class TokenizerTest < ActiveSupport::TestCase

  def test_splits_tokens_to_array
    assert_equal ["Chocolate", "Chip", "Cookies"], Tokenizer.process("Chocolate Chip Cookies ")
  end

  def test_deals_with_multiple_spaces
    assert_equal ["Chocolate", "Chip", "Cookies"], Tokenizer.process("Chocolate   Chip    Cookies ")
  end

end
