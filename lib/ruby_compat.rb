if RUBY_VERSION < '2.4'
  Hash.class_eval do
    def compact!
      delete_if {|_,v| v.nil?}
    end
  end
end
