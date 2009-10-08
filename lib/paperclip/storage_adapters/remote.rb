module Paperclip
  module Storage
    module Remote      
      def self.extended(base)
        base.instance_eval do      
          @client = Net::SFTP.start(@options[:host], @options[:username], {:password => @options[:password]}.merge(@options[:ssh_options] || {}) )            
          if options[:path] == self.class.default_options[:path]
            @path = "#{options[:upload_path]}:class/:id/:attachment/:style/:basename.:extension"
          else
            @path = options[:path]
          end
      
          if options[:url] == self.class.default_options[:url]
            @url = "/download/:class/:id/:attachment/:style/:basename.:extension"
          else
            @url = options[:url]
          end
        end
      end
    
      # send_data file.to_buffer, :disposition => 'inline', :content_type => file.content_type
      def to_buffer (style = default_style)
        @client.download!(path(style))
      end
  
      def exists? (style = default_style)
        begin
          @client.open!(path(style))
          return true
        rescue Net::SFTP::StatusException
          return false
        end   
      end
  
      def to_directory_array(path)
        directories = []
        directories_raw = path.split('/') and directories_raw.pop 

        path = directories_raw.shift
        directories_raw.each do |dir|
          directories << "#{path}/#{dir}" 
          path += "/#{dir}"
        end
    
        return directories
      end
  
      def create_directories(style)
        to_directory_array(path(style)).each do |dir|
          begin
            @client.mkdir!(dir)
          rescue
          end
        end
      end
  
      def remove_directories(path)
        to_directory_array(path).reverse.each do |dir|
          begin
            @client.rmdir!(dir)
          rescue
          end
        end        
      end
  
      def flush_writes #:nodoc:
        @queued_for_write.each do |style, file|
          file.close
      
          begin
            create_directories(style)
            log("Saving #{path(style)} to server.")
            @client.upload!(file.path, path(style))
          rescue
            log("Error Occured: #{$!}")
          end
        end
    
        @queued_for_write = {}
      end
  
      def flush_deletes
        @queued_for_delete.each do |file|
          begin
            log("Deleting #{file} from server.")
            @client.remove!(file)
            log("Removing empty directories.")
            remove_directories(file)
          rescue 
            log("Error Occured: #{$!}")
          end            
        end
    
        @queued_for_deletes = []
      end
    end
  end
end