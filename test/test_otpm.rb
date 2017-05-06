require_relative 'test_helper'

class OTPMTest < Minitest::Test
  def setup
    FakeFS.activate!
    FakeFS::FileSystem.clear
    auth_uri = 'otpauth://totp/ACME%20Co:john.doe@email.com' +
               '?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ' +
               '&issuer=ACME%20Co' +
               '&algorithm=SHA1' +
               '&digits=6' +
               '&period=30'
    @manager = OTPM::Manager.new('test-pass', storage_directory: '/tmp')
    @manager.store_account_from_google_uri(auth_uri)
    @manager.store_account('test',
                           'HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ',
                           issuer: 'test',
                           type: :hotp,
                           digits: 8,
                           counter: 0)
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_storing_creates_correct_files
    assert(File.exist?('/tmp/storage.otpdb'))
    assert_equal(2, @manager.list_accounts.length)
  end

  def test_initialization_vector_is_refreshed
    assert(File.exist?('/tmp/storage.otpdb'))
    config = YAML.load(File.open('/tmp/storage.otpdb', 'r').read())
    assert(config['initial_vector'])
    old_initial_vector = config['initial_vector']
    @manager.store_account('test@example.com', ROTP::Base32.random_base32)
    assert(File.exist?('/tmp/storage.otpdb'))
    config = YAML.load(File.open('/tmp/storage.otpdb', 'r').read())
    assert(!old_initial_vector.nil?)
    assert(!config['initial_vector'].nil?)
    assert(old_initial_vector != config['initial_vector'])

    # check that the backup has the old initial_vector
    config = YAML.load(File.open('/tmp/storage.otpdb.bck', 'r').read())
    assert(old_initial_vector == config['initial_vector'])
  end

  def test_all_keys_present_in_config
    assert(File.exist?('/tmp/storage.otpdb'))
    config = YAML.load(File.open('/tmp/storage.otpdb', 'r').read())
    assert_equal(config.keys.sort,
                 %w{version cipher_string iterations initial_vector key_length salt database}.sort)
  end

  def test_database_is_not_unencryped
    assert(File.exist?('/tmp/storage.otpdb'))
    bin_database = File.open('/tmp/storage.otpdb', 'r').read()
    assert_nil(bin_database.index('XDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ'))
    assert_nil(bin_database.index('john.doe@email.com'))
  end

  def test_unlocking_fails_with_wrong_password
    assert_raises OpenSSL::Cipher::CipherError do
      OTPM::Manager.new('wrong-pass', storage_directory: '/tmp')
    end
  end

  def test_show_account
    assert_equal(@manager.show_account('john.doe@email.com', issuer: 'ACME Co'),
                 {"user"     => "john.doe@email.com",
                  "secret"   => "HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ",
                  "issuer"   => "ACME Co",
                  "type"     => "totp",
                  "digits"   => 6,
                  "digest"   => "SHA1",
                  "interval" => 30,
                  "counter"  => 0})
  end

  def test_generate_six_digit_totp_code
    assert(/\d{6}/, @manager.generate_code('john.doe@email.com', issuer: 'ACME Co'))
  end

  def test_generate_eight_digit_hotp_code
    assert_equal(0, @manager.show_account('test', issuer: 'test')['counter'])
    code = @manager.generate_code('test', issuer: 'test')
    assert(/\d{8}/, code)
    assert_equal(1, @manager.show_account('test', issuer: 'test')['counter'])
    second_code = @manager.generate_code('test', issuer: 'test')
    assert(/\d{8}/, second_code)
    assert(code != second_code)
    assert_equal(2, @manager.show_account('test', issuer: 'test')['counter'])
  end

  def test_set_counter_on_hotp_account
    assert_equal(0, @manager.show_account('test', issuer: 'test')['counter'])
    @manager.set_counter('test', 67, issuer: 'test')
    assert_equal(67, @manager.show_account('test', issuer: 'test')['counter'])
  end

  def test_account_not_found_exception
    assert_raises OTPM::Storage::AccountNotFoundException do
      @manager.generate_code("foo", issuer: "not_bar")
    end
  end

  def test_backup_file_exists
    assert(File.exist?('/tmp/storage.otpdb.bck'))
  end
end
