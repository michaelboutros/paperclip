module Paperclip
  module Storage
    module Abstract
      def self.extended(base)
      end
      
      def exists?(style = default_style)
      end
      
      def to_file(style = default_file)
      end
      
      def flush_writes
      end
      
      def flush_deletes
      end
    end
  end
end
