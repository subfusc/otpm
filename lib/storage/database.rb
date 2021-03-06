require 'yaml'

module OTPM
  module Storage
    class Database

      def initialize(password, storage_directory: nil, storage_file: nil, config_file: nil)
        @storage_directory = storage_directory || File.join(Dir.home, ".cache", "otpm")
        @storage_file      = storage_file      || File.join(@storage_directory, "storage.bin")
        @config_file       = config_file       || File.join(@storage_directory, "storage.yml")

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
        @database[accessor]
      end

      def del_account!(user, issuer: '')
        @database.delete(account_key(user, issuer))
      end

      def list_accounts
        @database.map{|_,v| [v['user'], v['issuer']]}
      end

      def write!
        File.delete(@config_file)  if File.exist?(@config_file)
        File.delete(@storage_file) if File.exist?(@storage_file)

        blob = encrypt_database

        File.open(@storage_file, 'w') {|s| s.write(blob)}
        File.open(@config_file, 'w')  {|s| s.write(@config.to_yaml)}
      end

      private

      def account_key(user, issuer)
        format('%s:%s', user, issuer)
      end

      def decrypt_database
        read_blob
      end

      def encrypt_database
        @database.to_yaml
      end

      def gen_key(password)
      end

      def new_config
        {}
      end

      def read_blob
        File.open(@storage_file, 'r').read if File.exist?(@storage_file)
      end

      def read_config
        if File.exist?(@config_file)
          config = File.open(@config_file, 'r').read
          YAML.load(config)
        end
      end
    end
  end
end
