require_relative 'test_helper'
require 'pty'
require 'uuidtools'
require 'fileutils'

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

    db_dir = UUIDTools::UUID.random_create.to_s
    begin
      PTY.spawn("otpm -d #{db_dir}") do |output, input, pid|
        buffer = ""
        output.readpartial(1024, buffer)
        assert(buffer =~ /Encryption [\[\]a-z\/]+:/)
        input.puts("\n")
        output.readpartial(1024, buffer)
        output.readpartial(1024, buffer)
        assert(buffer =~ /password:/)
        input.puts("test-pass\n")
        output.readpartial(1024, buffer)
        assert(buffer =~ /repeat password:/)
        input.puts("test-pass\n")
        output.readpartial(1024, buffer) # Empty puts for newline need to be read
        output.readpartial(1024, buffer)
        assert(buffer =~ /otpm>\s+$/)
        input.puts("l\n")
        output.readpartial(1024, buffer) # Empty puts for newline need to be read
        output.readpartial(1024, buffer)
        assert(buffer =~ /^\s*otpm>\s+$/m)
        input.puts("u\n")
        output.readpartial(1024, buffer)
        output.readpartial(1024, buffer)
        assert(buffer =~ /otpauth uri:/)
        input.puts(auth_uri + "\n")
        output.readpartial(1024, buffer)
        output.readpartial(1024, buffer)
        assert(buffer =~ /^\s*otpm>\s+$/m)
        input.puts("l\n")
        output.readpartial(1024, buffer)
        output.readpartial(1024, buffer)
        input.puts("q\n")
      end
    ensure
      %x{rm #{db_dir}/storage.*}
      %x{rmdir #{db_dir}}
    end
  end
end
