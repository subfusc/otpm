require 'yaml'
require 'fileutils'
require 'digest'

module OTPM
  module Storage
    DEFAULT_DATABASE_LOCATION = File.join(Dir.home, ".cache", "otpm")
    DEFAULT_DATABASE_STORAGE  = "storage.otpdb"
    DATABASE_VERSION          = "0.1"
    SUPPORTED_ENCRYPTION_METHODS = [:cleartext, :blowfish, :aes]

    class Database

      def initialize(password, storage_directory: nil, storage_file: nil, config_file: nil)
        @storage_directory = storage_directory || DEFAULT_DATABASE_LOCATION
        @storage_file = Database.default_database_path(storage_directory: storage_directory,
                                                       storage_file: storage_file)

        FileUtils.mkdir_p(@storage_directory) unless Dir.exist?(@storage_directory)
        @config = read_config || new_config
        @key = gen_key(password)

        yaml_base = decrypt_database
        @database = if yaml_base
                      YAML.load(yaml_base)
                    else
                      {}
                    end
      end

      def Database.default_database_path(storage_directory: nil, storage_file: nil, config_file: nil)
        storage_directory = storage_directory || DEFAULT_DATABASE_LOCATION
        File.join(storage_directory, (storage_file || DEFAULT_DATABASE_STORAGE))
      end

      def add_account!(user, secret, issuer: '',
                       type: :totp, digits: 6,
                       digest: 'sha1', interval: 30, counter: 0)
        accessor = account_key(user, issuer)
        unless @database.has_key?(accessor)
          @database[accessor] = {'user'     => user,
                                 'secret'   => secret,
                                 'issuer'   => issuer,
                                 'type'     => type,
                                 'digits'   => digits,
                                 'digest'   => digest,
                                 'interval' => interval,
                                 'counter'  => counter}
        end
      end

      def get_account(user, issuer: '')
        accessor = account_key(user, issuer)
        index_of_entire_key = @database.keys.index{|key| key.start_with?(accessor)}
        if index_of_entire_key
          accessor = @database.keys[index_of_entire_key]
          @database[accessor]
        else
          raise AccountNotFoundException
        end
      end

      def increment_counter(user, issuer: '')
        get_account(user, issuer: issuer)['counter'] += 1
      end

      def set_counter(user, counter, issuer: '')
        get_account(user, issuer: issuer)['counter'] = Integer(counter)
      end

      def del_account!(user, issuer: '')
        user = get_account(user, issuer: issuer) # Do a serch in case of partial account from
        @database.delete(account_key(user['user'], user['issuer']))
      end

      def list_accounts
        @database.map do |_,v|
          v.select{|k,_| ['user', 'issuer', 'type', 'counter', 'interval', 'digits'].include?(k)}
        end
      end

      def write!
        File.delete(@storage_file + '.bck') if File.exist?(@storage_file + '.bck')
        FileUtils.mv(@storage_file, @storage_file + '.bck') if File.exist?(@storage_file)

        blob = encrypt_database
        @config['database'] = blob
        sha = Digest::SHA2.hexdigest(@config.to_yaml)
        File.open(@storage_file, 'w')  {|s| s.write(@config.to_yaml)}

        unless Digest::SHA2.hexdigest(File.open(@storage_file, 'r').read()) == sha
          raise DatabaseInconsistencyException
        end
      end

      private

      def account_key(user, issuer)
        issuer && !issuer.empty? ? format('%s:%s', user, issuer) : user
      end

      def decrypt_database
        get_blob
      end

      def encrypt_database
        @database.to_yaml
      end

      def gen_key(password)
      end

      def new_config
        {'version' => DATABASE_VERSION}
      end

      def get_blob
        @config['database']
      end

      def read_config
        if File.exist?(@storage_file)
          config = File.open(@storage_file, 'r').read
          YAML.load(config)
        end
      end
    end
  end
end
