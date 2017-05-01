require_relative 'test_helper'
require 'pty'
require 'uuidtools'
require 'fileutils'
require 'timeout'

class OTPMBinTest < Minitest::Test

  def test_version
    assert_equal(OTPM::VERSION, %x{otpm -v}.chomp)
  end

  def test_help
    assert(!%{otpm -h}.chomp.empty?)
  end

  def test_normal_usecase
    auth_uri = 'otpauth://totp/ACME%20Co:john.doe@email.com' +
               '?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ' +
               '&issuer=ACME%20Co' +
               '&algorithm=SHA1' +
               '&digits=6' +
               '&period=30'

    readline_until_expected = lambda do |input, expected|
      Timeout.timeout(3) do
        buffer = input.readchar
        while not expected.match(buffer)
          buffer += input.readchar
        end
        buffer
      end
    end

    db_dir = UUIDTools::UUID.random_create.to_s
    begin
      PTY.spawn("otpm -d #{db_dir}") do |output, input, pid|
        buffer = readline_until_expected.(output, /Encryption [\[\]a-z\/]+:/)
        assert(buffer =~ /Encryption [\[\]a-z\/]+:/)
        input.puts("\n")
        buffer = readline_until_expected.(output, /password:/)
        assert(buffer =~ /password:/)
        input.puts("test-pass\n")
        buffer = readline_until_expected.(output, /repeat password:/)
        assert(buffer =~ /repeat password:/)
        input.puts("test-pass\n")
        buffer = readline_until_expected.(output, /otpm>\s+$/)
        assert(buffer =~ /otpm>\s+$/)
        input.puts("l\n")
        buffer = readline_until_expected.(output, /^\s*otpm>\s+$/m)
        assert(buffer =~ /^\s*otpm>\s+$/m)
        input.puts("u\n")
        buffer = readline_until_expected.(output, /otpauth uri:/)
        assert(buffer =~ /otpauth uri:/)
        input.puts(auth_uri + "\n")
        buffer = readline_until_expected.(output, /^\s*otpm>\s+$/m)
        assert(buffer =~ /^\s*otpm>\s+$/m)
        input.puts("l\n")
        buffer = readline_until_expected.(output, /^\s*otpm>\s+$/m)
        input.puts("q\n")
      end
    ensure
      %x{rm #{db_dir}/storage.*}
      %x{rmdir #{db_dir}}
    end
  end
end
