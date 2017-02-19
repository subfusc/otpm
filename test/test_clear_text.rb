require_relative 'test_helper'

class ClearTextTest < Minitest::Test
  def setup
    FakeFS.activate!
    FakeFS::FileSystem.clear
    auth_uri = 'otpauth://totp/ACME%20Co:john.doe@email.com' +
               '?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ' +
               '&issuer=ACME%20Co' +
               '&algorithm=SHA1' +
               '&digits=6' +
               '&period=30'
    @manager = OTPM::Manager.new('test-pass', storage_directory: '/tmp', database_type: :plaintext)
    @manager.store_account_from_google_uri(auth_uri)
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_database_is_not_encryped
    assert(File.exist?('/tmp/storage.bin'))
    bin_database = File.open('/tmp/storage.bin', 'r').read()
    assert(bin_database.index('XDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ'))
    assert(bin_database.index('john.doe@email.com'))
  end
end
