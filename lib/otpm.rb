require 'storage/database'
require 'storage/bf_database'
require 'rotp'
require 'uri'

module OTPM
  class Manager

    def initialize(password, database_type: :blowfish, storage_directory: nil)
      @db = case database_type
            when :blowfish
              Storage::BfDatabase.new(password, storage_directory: storage_directory)
            when :plaintext
              Storage::Database.new(password, storage_directory: storage_directory)
            else raise(format("%s is not a supported database type ATM.", database_type))
            end
    end


    def generate_code(user, issuer: '')
      account = @db.get_account(user, issuer: issuer)
      case account['type']
      when :totp
        totp = ROTP::TOTP.new(account['secret'], {digits:   account['digits'],
                                                  digest:   account['algorithm'],
                                                  interval: account['interval'],
                                                  issuer:   account['issuer']})
        totp.now
      when :hotp
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


    def store_account_from_google_uri(google_style_uri)
      # see https://github.com/google/google-authenticator/wiki/Key-Uri-Format
      # TODO
      raise('Not implemented yet.')
    end

  end
end
