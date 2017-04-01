require_relative 'test_helper'

class OTPMBlowfishTest < Minitest::Test
  def setup
    FakeFS.activate!
    FakeFS::FileSystem.clear
    auth_uri = 'otpauth://totp/ACME%20Co:john.doe@email.com' +
               '?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ' +
               '&issuer=ACME%20Co' +
               '&algorithm=SHA1' +
               '&digits=6' +
               '&period=30'
    @manager = OTPM::Manager.new('test-pass', database_type: :blowfish, storage_directory: '/tmp')
    @manager.store_account_from_google_uri(auth_uri)
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_storing_creates_correct_files
    assert(File.exist?('/tmp/storage.bin'))
    assert(File.exist?('/tmp/storage.yml'))
    assert_equal(1, @manager.list_accounts.length)
  end

  def test_initialization_vector_is_refreshed
    assert(File.exist?('/tmp/storage.yml'))
    config = YAML.load(File.open('/tmp/storage.yml', 'r').read())
    assert(config['initial_vector'])
    old_initial_vector = config['initial_vector']
    @manager.store_account('test@example.com', ROTP::Base32.random_base32)
    assert(File.exist?('/tmp/storage.yml'))
    config = YAML.load(File.open('/tmp/storage.yml', 'r').read())
    assert(!old_initial_vector.nil?)
    assert(!config['initial_vector'].nil?)
    assert(old_initial_vector != config['initial_vector'])
  end

  def test_database_is_not_unencryped
    assert(File.exist?('/tmp/storage.bin'))
    bin_database = File.open('/tmp/storage.bin', 'r').read()
    assert_nil(bin_database.index('XDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ'))
    assert_nil(bin_database.index('john.doe@email.com'))
  end

  def test_unlocking_fails_with_wrong_password
    assert_raises OpenSSL::Cipher::CipherError do
      OTPM::Manager.new('wrong-pass', storage_directory: '/tmp')
    end
  end
end
