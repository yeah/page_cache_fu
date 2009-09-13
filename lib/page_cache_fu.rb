module PageCacheFu
  module Patches
    module CachingPagesClassMethods
  
      def caches_page_with_expiry(*actions)
        if actions.last.is_a?(::Hash)
          self.page_cache_fu_options ||= {}
          actions[0..-2].each do |action|
            self.page_cache_fu_options[action.to_sym] = actions.last
          end
        end
        caches_page_without_expiry(*actions)
      end

      def self.included(base)
        base.send(:alias_method_chain, :caches_page, :expiry)
      end

    end

    module CachingPages

      def expire_page_with_domain_and_query(options)
        expire_page_without_domain_and_query(page_cache_fu_path(options))
      end
      
      def cache_page_with_domain_and_query(content = nil, options = nil)
        path = page_cache_fu_path(options)
        cache_page_without_domain_and_query(content, path)
      end

      def cache_page_with_expiry(content = nil, options = nil)
        cache_page_without_expiry(content, options)
        if self.class.page_cache_fu_options[params[:action].to_sym] and (expires_in = self.class.page_cache_fu_options[params[:action].to_sym][:expires_in])
          expires_at = Time.now + expires_in
          file = self.class.send(:page_cache_path, options)
          File.utime(expires_at, expires_at, file) if File.exists?(file)
        end
      end

      def self.included(base)
        base.send(:alias_method_chain, :expire_page, :domain_and_query)
        base.send(:alias_method_chain, :cache_page, :expiry)
        base.send(:alias_method_chain, :cache_page, :domain_and_query)
      end

    end
    
    module Base
      def page_cache_fu_path(orig_path)

        page_cache_fu_options = case orig_path
          when Hash
            self.class.page_cache_fu_options[orig_path[:action].to_sym]
          when String
            {}
          else
            self.class.page_cache_fu_options[self.request[:action].to_sym]
        end

        path = (page_cache_fu_options[:page_cache_directory]||"/#{self.request.host}/")
        path << case orig_path
          when Hash
            url_for(orig_path.merge(:only_path => true, :skip_relative_url_root => true, :format => params[:format]))
          when String
            orig_path
          else
            if self.request.path.empty? || self.request.path == '/'
              '/index'
            else
              self.request.path
            end
        end
        path << CGI::escape(self.request.query_string) if !self.request.query_string.blank? and page_cache_fu_options[:include_query_string] != false
        return path
      end
      
    end
  end
  module CacheSweeper
    def self.sweep_if_expired(file, options={})
      if File.exists?(file)
        if options[:match_mode].nil? or mode_match((mode=sprintf('%o',File.stat(file).mode)[-3,3]), options[:match_mode])
          if File.directory?(file)
            if options[:not_if_directory]
              puts "Skipping directory #{file}. (Call with :recursive => true to sweep recursively.)"
            else
              Dir.foreach(file) do |subfile|
                sweep_if_expired(file+ '/'+ subfile, options.merge({:not_if_directory => !options[:recursive]})) unless ['.','..'].include?(subfile)
              end
            end
          else
            if File.mtime(file) < Time.now
              puts "Sweeping #{file}. #{File.mtime(file)} < #{Time.now}"
              File.delete(file)
            end
          end
        else
          puts "Skipping file/directory #{file}. Mode does not match. (requested mode: #{options[:match_mode]}. actual mode: #{mode})"
        end
      end
    end

    private

    def self.mode_match(mode1, mode2)
      mode1, mode2 = mode1.to_s, mode2.to_s
      length = [mode1.size,mode2.size].max
      mode1, mode2 = ("%0#{length}d" % mode1), ("%0#{length}d" % mode2)
      match = true
      0.upto(length-1) do |i|
        unless mode1[i].to_i & mode2[i].to_i == mode2[i].to_i
          match = false
          break
        end
      end
      return match
    end
  end

end
