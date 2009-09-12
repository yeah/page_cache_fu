module PageCacheFu
  module Patches
    module ClassMethods
  
      def caches_page_with_expiry(*actions)
        if actions.last.is_a?(::Hash) and (expires_in = actions.last.delete(:expires_in))
          self.expiry_page_cache_options ||= {}
          actions[0..-2].each do |action|
            self.expiry_page_cache_options[action.to_sym] = (Time.now + expires_in)
          end
        end
        caches_page_without_expiry(*actions)
      end

      def self.included(base)
        base.send(:alias_method_chain, :caches_page, :expiry)
      end

    end

    module InstanceMethods

      def expire_page_with_domain_and_query(options)
        expire_page_without_domain_and_query(PageCacheFu::page_cache_path_with_domain_and_query(options, request))
      end
      
      def cache_page_with_domain_and_query(content = nil, options = nil)
        path = PageCacheFu::page_cache_path_with_domain_and_query(options, request)
        cache_page_without_domain_and_query(content, path)
      end

      def cache_page_with_expiry(content = nil, options = nil)
        cache_page_without_expiry(content, options)
        if self.class.expiry_page_cache_options and (expires_in = self.class.expiry_page_cache_options[params[:action].to_sym])
          file = self.class.send(:page_cache_path, PageCacheFu::page_cache_path_with_domain_and_query((options||request.path), request))
          File.utime(expires_in.to_time, expires_in.to_time, file) if File.exists?(file)
        end
      end

      def self.included(base)
        base.send(:alias_method_chain, :expire_page, :domain_and_query)
        base.send(:alias_method_chain, :cache_page, :domain_and_query)
        base.send(:alias_method_chain, :cache_page, :expiry)
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

  def self.page_cache_path_with_domain_and_query(orig_path, request)
    path = "/#{request.host}/"
    path << case orig_path
    when Hash
      url_for(orig_path.merge(:only_path => true, :skip_relative_url_root => true, :format => params[:format]))
    when String
      orig_path
    else
      if request.path.empty? || request.path == '/'
        '/index'
      else
        request.path
      end
    end
    path << CGI::escape(request.query_string) unless request.query_string.blank?
    return path
  end


end
