require 'openssl'

module OTPM
  module Storage
    class BfDatabase < Database

      private

      def gen_key(password)
        OpenSSL::PKCS5.pbkdf2_hmac_sha1(password,
                                        @config['salt'],
                                        @config['iterations'],
                                        @config['key_length'])
      end

      def new_config
        {'cipher_string' => 'bf-cbc',
         'iterations'    => rand(2000..10000),
         'key_length'    => 16,
         'salt'          => OpenSSL::Random.random_bytes(16)}
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
