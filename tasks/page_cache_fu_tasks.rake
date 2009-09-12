namespace :page_cache_fu do
  desc "Sweeps the cached pages which are expired."
  task :sweep_expired_page_caches => :environment do
    PageCacheFu::CacheSweeper.sweep_if_expired(ActionController::Base.page_cache_directory, :recursive => true)
  end
end
