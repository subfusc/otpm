require 'openssl'

module OTPM
  module Storage
    class AESDatabase < Database

      private

      def gen_key(password)
        OpenSSL::PKCS5.pbkdf2_hmac_sha1(password,
                                        @config['salt'],
                                        @config['iterations'],
                                        @config['key_length'])
      end

      def new_config
        conf = super()
        conf.merge({'cipher_string' => 'AES-256-CBC',
                    'iterations'    => rand(2000..10000),
                    'key_length'    => 32,
                    'salt'          => OpenSSL::Random.random_bytes(32)})
      end

      def encrypt_database
        cipher = OpenSSL::Cipher.new(@config['cipher_string'])
        cipher.encrypt
        cipher.key = @key
        new_iv = cipher.random_iv
        @config['initial_vector'] = new_iv
        cipher.update(@database.to_yaml) + cipher.final
      end

      def decrypt_database
        if (blob = get_blob)
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
