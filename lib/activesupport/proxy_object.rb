# frozen_string_literal: true

module ActiveSupport
  class ProxyObject < ::BasicObject
    undef_method :==
    undef_method :equal?

    def raise(*args)
      ::Object.send(:raise, *args)
    end
  end
end
