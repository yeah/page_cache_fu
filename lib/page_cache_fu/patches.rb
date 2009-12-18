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
        begin
          cache_page_without_expiry(content, options)
        rescue Errno::EEXIST # rescue error caused by race condition on filesystem, this should be done in Rails' ActionController::Caching::Pages::ClassMethods#cache_page
        rescue Errno::EISDIR # weird uris including forward slashes produce this. so what, just be quiet about it.
        end
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

        page_cache_fu_options = self.class.page_cache_fu_options.nil? ? {} : case orig_path
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
end