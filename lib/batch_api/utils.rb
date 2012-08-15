module BatchApi
  module Utils

    def self.deep_dup(object)
      if object.is_a?(Hash)
        duplicate = object.dup
        duplicate.each_pair do |k,v|
          tv = duplicate[k]
          duplicate[k] = tv.is_a?(Hash) && v.is_a?(Hash) ? deep_dup(tv) : v
        end
        duplicate
      else
        object
      end
    end
  end
end
