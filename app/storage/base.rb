module Storage
  class Base
    def store(*)
      raise NotImplementedError, "#{self.class} must implement #store"
    end

    def retrieve(*)
      raise NotImplementedError, "#{self.class} must implement #retrieve"
    end
  end
end
