require 'storage/database'
require 'storage/bf_database'
require 'storage/aes_database'
require 'ruby_compat'
require 'rotp'
require 'version'
require 'uri'

module OTPM

  class Manager

    def initialize(password, database_type: :aes, storage_directory: nil)
      @db = case database_type
            when :aes
              Storage::AESDatabase.new(password, storage_directory: storage_directory)
            when :blowfish
              Storage::BfDatabase.new(password,  storage_directory: storage_directory)
            when :plaintext
              Storage::Database.new(password,    storage_directory: storage_directory)
            else raise(format("%s is not a supported database type ATM.", database_type))
            end
    end


    def self.database_exist?(storage_directory = nil)
      File.exist?(storage_directory || Storage::DEFAULT_DATABASE_LOCATION)
    end

    def generate_code(user, issuer: '')
      account = @db.get_account(user, issuer: issuer)
      case account['type']
      when 'totp'
        totp = ROTP::TOTP.new(account['secret'], {digits:   account['digits'],
                                                  digest:   account['algorithm'],
                                                  interval: account['interval'],
                                                  issuer:   account['issuer']})
        totp.now
      when 'hotp'
        raise('Not implemented yet') # TODO
      else raise('Unsupported type')
      end
    end


    def list_accounts
      @db.list_accounts
    end


    def store_account(user, secret, issuer: '',
                      type: :totp, digits: 6, digest: 'sha1',
                      interval: 30, counter: 0)
      @db.add_account!(user, secret,
                       issuer:   issuer,
                       type:     type,
                       digits:   digits,
                       digest:   digest,
                       interval: interval,
                       counter:  counter)
      @db.write!
    end

    # see https://github.com/google/google-authenticator/wiki/Key-Uri-Format
    def store_account_from_google_uri(google_style_uri)
      uri = URI.parse(google_style_uri)
      raise('Not a otpauth url') unless uri.scheme == 'otpauth'
      issuer, user = uri.path.split(':')
      issuer = CGI::unescape(issuer[1..-1]) if issuer
      params = Hash[uri.query.split('&').
                     map{|s| s.split('=')}.
                     map{|pair| pair.map{|s| CGI::unescape(s)}}]

      if issuer && params['issuer'] && issuer != params['issuer']
        raise('Issuer parameter and prefix does not match')
      end

      params_translated = {digits: params['digits']&.to_i,
                           digest: params['algorithm'],
                           interval: params['period']&.to_i,
                           type: uri.host,
                           issuer: issuer,
                           counter: params['counter']&.to_i}.compact!

      store_account(user, params['secret'], **params_translated)
    end

  end
end
