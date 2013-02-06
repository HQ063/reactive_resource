module ReactiveResource
  module Association
    # Represents and resolves a has_many association.
    class HasManyAssociation

      # The class this association is attached to
      attr_reader :klass

      # The attribute name this association represents
      attr_reader :attribute

      # additional options passed in when the association was created
      attr_reader :options

      # Returns the class name of the target of the association. Based
      # off of +attribute+ unless +class_name+ was passed in the
      # +options+ hash.
      def associated_class
        if options[:class_name]
          options[:class_name].constantize
        else
          klass.relative_const_get(attribute.to_s.singularize.camelize)
        end
      end

      def resolve_modes
        if options[:resolve_modes]
          options[:resolve_modes]
        else
          {:use_url_property => true, :use_nested_url => true}
        end
      end

      # Called when this assocation is referenced. Finds and returns
      # the targets of this association.
      def resolve_relationship(object, attribute)
        ret = nil
        if(resolve_modes[:use_url_property] == true)
          if object.attributes["#{attribute.to_s}_url"]
            ret = associated_class.find_by_url(object.attributes["#{attribute.to_s}_url"])
          end
        end
        if(ret.nil? && resolve_modes[:use_nested_url] == true)
          id_attribute = "#{klass.name.split("::").last.underscore}_id"
          ret = associated_class.find(:all, :params => object.prefix_options.merge(id_attribute => object.id))
        end
        if ret.nil?
          ret = []
        end
        ret
      end
      
      # Adds methods for has_many associations, to make dealing with
      # these objects a bit more straightforward. If the attribute name
      # is +lawyers+, it will add:
      #
      # [lawyers] returns the associated lawyers
      def add_helper_methods(klass, attribute)
        association = self
        klass.class_eval do 
          # lawyer.addresses
          define_method(attribute) do
            unless instance_variable_get("@#{attribute}")
              object = association.resolve_relationship(self, attribute)
              instance_variable_set("@#{attribute}", object)
            end
            instance_variable_get("@#{attribute}")
          end
        end
      end
      
      # Create a new has_many association.
      def initialize(klass, attribute, options)
        @klass = klass
        @attribute = attribute
        @options = options

        add_helper_methods(klass, attribute)
      end
    end
  end
end
