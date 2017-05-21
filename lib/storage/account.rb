module OTPM
  module Storage
    class Account

      def initialize(username, secret, issuer: nil,
                     type: :totp, digits: 6,
                     digest: 'sha1', interval: 30, counter: 0)
        @username = username
        @secret = secret
        @issuer = issuer
        @type = type
        @digits = digits
        @digest = digest
        @interval = interval
        @counter = counter
      end

      def
    end
  end
end
