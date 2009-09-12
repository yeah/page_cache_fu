require 'dispatcher'
# require 'lib/page_cache_fu.rb'
Dispatcher.to_prepare do

  ApplicationController.send(:class_inheritable_accessor, :page_cache_fu_options)

  if File.expand_path(ActionController::Base.page_cache_directory) == File.expand_path('public',RAILS_ROOT)
    ActionController::Base.page_cache_directory = File.expand_path('public/cache',RAILS_ROOT)
  end

  unless ActionController::Caching::Pages::ClassMethods.include?(PageCacheFu::Patches::CachingPagesClassMethods)
    ActionController::Caching::Pages::ClassMethods.send(:include, PageCacheFu::Patches::CachingPagesClassMethods) 
  end

  unless ActionController::Caching::Pages.include?(PageCacheFu::Patches::CachingPages)
    ActionController::Caching::Pages.send(:include, PageCacheFu::Patches::CachingPages) 
  end

  unless ActionController::Base.include?(PageCacheFu::Patches::Base)
    ActionController::Base.send(:include, PageCacheFu::Patches::Base) 
  end

end