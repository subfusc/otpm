require_relative 'test_helper'

class OTPMTest < Minitest::Test
  def setup
    FakeFS.activate!
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_storing_creates_correct_files
    manager = OTPM::Manager.new('test-pass', storage_directory: '/tmp')
    manager.store_account('test@example.com', ROTP::Base32.random_base32)
    assert(File.exist?('/tmp/storage.bin'))
    assert(File.exist?('/tmp/storage.yml'))
    assert_equal(1, manager.list_accounts.length)
  end
end
