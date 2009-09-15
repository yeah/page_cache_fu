module PageCacheFu
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
  end
end