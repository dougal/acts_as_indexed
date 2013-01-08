require 'unit_test_helper.rb'
include ActsAsIndexed

class TokenNormalizerTest < ActiveSupport::TestCase

  def test_leaves_case_of_tokens_untouched
    assert_equal ["Chocolate", "Chip", "Cookies"], TokenNormalizer.process(["Chocolate", "Chip", "Cookies"])
  end

  def test_downcases_tokens
    assert_equal ["chocolate", "chip", "cookies"], TokenNormalizer.process(["Chocolate", "Chip", "Cookies"], :normalize_case => true)
  end

  def test_limits_min_length_to_five
    assert_equal ["Chocolate", "Cookies"], TokenNormalizer.process(["Chocolate", "Chip", "Cookies"], :min_token_length => 5)
  end

  def test_limits_min_length_to_four
    assert_equal ["Love", "Chocolate", "Chip", "Cookies"], TokenNormalizer.process(["I", "Love", "Chocolate", "Chip", "Cookies"], :min_token_length => 4)
  end

  def test_downcases_and_limits_min_length_to_four
    assert_equal ["love", "chocolate", "chip", "cookies"], TokenNormalizer.process(["I", "Love", "Chocolate", "Chip", "Cookies"], :normalize_case => true, :min_token_length => 4)
  end

end
