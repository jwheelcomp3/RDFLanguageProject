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

  def test_bad_path
    argument_mock = ['/dev/null/nowhere']
    begin
      Driver.new argument_mock
    rescue SystemExit => e
      assert_equal e.status, 2
    end
  end
end

def puts(*args)
end