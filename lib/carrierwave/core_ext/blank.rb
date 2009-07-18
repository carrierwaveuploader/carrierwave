# encoding: utf-8

unless "".respond_to?(:blank?)
  # blank? methods for several different class types
  class Object
    # Returns true if the object is nil or empty (if applicable)
    def blank?
      nil? || (respond_to?(:empty?) && empty?)
    end
  end # class Object

  class Numeric
    # Numerics can't be blank
    def blank?
      false
    end
  end # class Numeric

  class NilClass
    # Nils are always blank
    def blank?
      true
    end
  end # class NilClass

  class TrueClass
    # True is not blank.
    def blank?
      false
    end
  end # class TrueClass

  class FalseClass
    # False is always blank.
    def blank?
      true
    end
  end # class FalseClass

  class String
    # Strips out whitespace then tests if the string is empty.
    def blank?
      strip.empty?
    end
  end # class String
end