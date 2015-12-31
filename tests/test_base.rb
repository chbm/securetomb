require "./lib/securetomb"
require "test/unit"

class TestSecureTomb < Test::Unit::TestCase

  def test_fileset
    assert(FileSet.new)
  end

end
