module PluckMap
  module Struct
    module ClassMethods
      def presenter
        @presenter || superclass.presenter
      end

      def load(relation)
        presenter.to_h(relation).map { |values| new(**values) }
      end
    end
  end
end
