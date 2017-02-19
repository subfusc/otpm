require 'openssl'
require 'yaml'

module OTPM
  module Storage
    class BfDatabase

      def initialize(password, storage_directory: nil, storage_file: nil, config_file: nil)
        @storage_directory = storage_directory || File.join(Dir.home, ".cache", "otpm")
        @storage_file      = storage_file      || File.join(@storage_directory, "key_storage.bf")
        @config_file       = config_file       || File.join(@storage_directory, "storage.yml")

        Dir.mkdir(@storage_directory) unless Dir.exists?(@storage_directory)
        @config = read_config || new_config
        @key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(password,
                                               @config['salt'],
                                               @config['iterations'],
                                               @config['key_length'])

        yaml_base = decrypt_database
        @database = if yaml_base
                      YAML.load(yaml_base)
                    else
                      {}
                    end
      end

      def add_account!(provider, secret, account: nil)
        unless @database.has_key?(provider)
          @database[provider] = {'secret' => secret}
          @database[provider]['account'] = account if account
        end
      end

      def write!
        File.delete(@config_file)  if File.exists?(@config_file)
        File.delete(@storage_file) if File.exists?(@storage_file)

        cipher = OpenSSL::Cipher.new(@config['cipher_string'])
        cipher.encrypt
        cipher.key = @key
        new_iv = cipher.random_iv
        File.open(@storage_file, 'w') {|s| s.write(cipher.update(@database.to_yaml) + cipher.final)}
        @config['initial_vector'] = new_iv
        File.open(@config_file, 'w')  {|s| s.write(@config.to_yaml)}
      end

      private

      def read_config
        if File.exists?(@config_file)
          config = File.open(@config_file, 'r').read
          YAML.load(config)
        end
      end

      def new_config
        {'cipher_string' => 'bf-cbc',
         'iterations'    => rand(2000..10000),
         'key_length'    => 16,
         'salt'          => OpenSSL::Random.random_bytes(16)}
      end

      def read_blob
        File.open(@storage_file, 'r').read if File.exists?(@storage_file)
      end

      def decrypt_database
        if (blob = read_blob)
          decipher = OpenSSL::Cipher.new(@config['cipher_string'])
          decipher.decrypt
          decipher.key = @key
          decipher.iv = @config['initial_vector']
          decipher.update(blob) + decipher.final
        end
      end
    end
  end
end
