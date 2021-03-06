module Mailman
  class Route

    # Matches against the To addresses of a message.
    class ToCondition < Condition
      def match(message)
        # this is done for cases where the `to` field is missing but does
        # have a `Delivered-To` - so we pick from that instead
        unless message.to.nil? && message.header['Delivered-To'].nil?
          messageto = message.to.is_a?(Array) ? message.to : [message.to]
          messageto_from_headers = [message.header['Delivered-To']].flatten
                                                                   .compact
                                                                   .map(&:to_s)
          messageto.concat(messageto_from_headers)
          messageto.each do |address|
            if result = @matcher.match(address)
              return result
            end
          end
        end
        nil
      end
    end

    # Matches against the From addresses of a message.
    class FromCondition < Condition
      def match(message)
        message.from.each do |address|
          if result = @matcher.match(address)
            return result
          end
        end
        nil
      end
    end

    # Matches against the Subject of a message.
    class SubjectCondition < Condition
      def match(message)
        @matcher.match(message.subject)
      end
    end

    # Matches against the Body of a message.
    class BodyCondition < Condition
      def match(message)
        if message.multipart?
          result = nil
          message.parts.each do |part|
            break if result = @matcher.match(part.decoded)
          end
          return result
        else
          @matcher.match(message.body.decoded)
        end
      end
    end

    # Matches against the CC header of a message.
    class CcCondition < Condition
      def match(message)
        if !message.cc.nil?
          message.cc.each do |address|
            if result = @matcher.match(address)
              return result
            end
          end
        end
        nil
      end
    end
    
    class HeaderCondition < Condition
      def match(message)
        @matcher.match(message.header)
      end      
    end
  end
end
