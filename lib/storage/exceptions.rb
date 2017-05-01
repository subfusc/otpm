module OTPM
  module Storage
    class AccountNotFoundException < StandardError
    end

    class DatabaseInconsistencyException < StandardError
    end
  end
end
