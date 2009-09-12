require 'dispatcher'
# require 'lib/page_cache_fu.rb'
Dispatcher.to_prepare do

  ApplicationController.send(:class_inheritable_accessor, :expiry_page_cache_options)

  if File.expand_path(ActionController::Base.page_cache_directory) == File.expand_path('public',RAILS_ROOT)
    ActionController::Base.page_cache_directory = File.expand_path('public/cache',RAILS_ROOT)
  end

  unless ActionController::Caching::Pages::ClassMethods.include?(PageCacheFu::Patches::ClassMethods)
    ActionController::Caching::Pages::ClassMethods.send(:include, PageCacheFu::Patches::ClassMethods) 
  end

  unless ActionController::Caching::Pages.include?(PageCacheFu::Patches::InstanceMethods)
    ActionController::Caching::Pages.send(:include, PageCacheFu::Patches::InstanceMethods) 
  end

end