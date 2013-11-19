require 'minitest/autorun'

require './rdfgen'

class TestDriver < MiniTest::Test
  def test_no_arguments
    argument_mock = []
    begin
      Driver.new argument_mock
    rescue SystemExit => e
      assert_equal e.status, 1
    end
  end

  def test_superfluous_arguments

  end

  def test_bad_path
    argument_mock = %w(/dev/null/nowhere)
    begin
      Driver.new argument_mock
    rescue SystemExit => e
      assert_equal e.status, 2
    end
  end

  def test_valid_path

  end
end

# Dummy method to suppress console output when running tests
def puts(*args)
end