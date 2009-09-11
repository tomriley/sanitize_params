module SanitizeParams
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      def sanitize_params
        if request.post? || request.put?
          self.class.read_inheritable_attribute(:_param_sanitizers).each do |sanitizer|
            sanitizer.call(self)
          end
        end
      end
    end
  end
  
  module ClassMethods
    def sanitize_param(key1, key2 = nil, method = nil, &block)
      write_inheritable_array :_param_sanitizers, [Proc.new { |controller|
        if controller.params[key1]
          if !key2
            logger.debug "Sanitizing params[#{key1}]"
            controller.params[key1] = if block_given?
              block.call(controller, controller.params[key1])
            else
              controller.send(method, controller.params[key1])
            end
          elsif key2 && controller.params[key1][key2] 
            logger.debug "Sanitizing params[#{key1}][#{key2}]"
            controller.params[key1][key2] = if block_given?
              block.call(controller, controller.params[key1][key2])
            else
              controller.send(method, controller.params[key1][key2])
            end
          end
        end
      }]
      before_filter :sanitize_params
    end
  end
end
