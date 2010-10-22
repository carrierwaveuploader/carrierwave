# BACKPORTED FROM ACTIVESUPPORT 3.0

module ActiveSupport
  # A typical module looks like this:
  #
  #   module M
  #     def self.included(base)
  #       base.extend, ClassMethods
  #       base.send(:include, InstanceMethods)
  #       scope :disabled, where(:disabled => true)
  #     end
  #
  #     module ClassMethods
  #       ...
  #     end
  #
  #     module InstanceMethods
  #       ...
  #     end
  #   end
  #
  # By using <tt>ActiveSupport::Concern</tt> the above module could instead be written as:
  #
  #   require 'active_support/concern'
  #
  #   module M
  #     extend ActiveSupport::Concern
  #
  #     included do
  #       scope :disabled, where(:disabled => true)
  #     end
  #
  #     module ClassMethods
  #       ...
  #     end
  #
  #     module InstanceMethods
  #       ...
  #     end
  #   end
  #
  # Moreover, it gracefully handles module dependencies. Given a +Foo+ module and a +Bar+
  # module which depends on the former, we would typically write the following:
  #
  #   module Foo
  #     def self.included(base)
  #       base.class_eval do
  #         def self.method_injected_by_foo
  #           ...
  #         end
  #       end
  #     end
  #   end
  #
  #   module Bar
  #     def self.included(base)
  #       base.method_injected_by_foo
  #     end
  #   end
  #
  #   class Host
  #     include Foo # We need to include this dependency for Bar
  #     include Bar # Bar is the module that Host really needs
  #   end
  #
  # But why should +Host+ care about +Bar+'s dependencies, namely +Foo+? We could try to hide
  # these from +Host+ directly including +Foo+ in +Bar+:
  #
  #   module Bar
  #     include Foo 
  #     def self.included(base)
  #       base.method_injected_by_foo
  #     end
  #   end
  #
  #   class Host
  #     include Bar
  #   end
  #
  # Unfortunately this won't work, since when +Foo+ is included, its <tt>base</tt> is the +Bar+ module,
  # not the +Host+ class. With <tt>ActiveSupport::Concern</tt>, module dependencies are properly resolved:
  #
  #   require 'active_support/concern'
  #
  #   module Foo
  #     extend ActiveSupport::Concern
  #     included do
  #       class_eval do
  #         def self.method_injected_by_foo
  #           ...
  #         end
  #       end
  #     end
  #   end
  #
  #   module Bar
  #     extend ActiveSupport::Concern
  #     include Foo
  #
  #     included do
  #       self.method_injected_by_foo
  #     end
  #   end
  #
  #   class Host
  #     include Bar # works, Bar takes care now of its dependencies
  #   end
  #
  module Concern
    def self.extended(base)
      base.instance_variable_set("@_dependencies", [])
    end

    def append_features(base)
      if base.instance_variable_defined?("@_dependencies")
        base.instance_variable_get("@_dependencies") << self
        return false
      else
        return false if base < self
        @_dependencies.each { |dep| base.send(:include, dep) }
        super
        base.extend const_get("ClassMethods") if const_defined?("ClassMethods")
        base.send :include, const_get("InstanceMethods") if const_defined?("InstanceMethods")
        base.class_eval(&@_included_block) if instance_variable_defined?("@_included_block")
      end
    end

    def included(base = nil, &block)
      if base.nil?
        @_included_block = block
      else
        super
      end
    end
  end
end
