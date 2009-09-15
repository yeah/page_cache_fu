require 'ftools'

# Remove page_cache_sweeper from the local script directory.
#
# If page_cache_sweeper doesn't exists, print a warning and exit.
#
if File.directory? "script"
  dest_dir = "script"
end

dest_sweeper_file = File.join(dest_dir, "page_cache_sweeper") if dest_dir

if !dest_dir
  STDERR.puts "Could not find a script directory. Please remove the page_cache_sweeper script manually."
elsif !File::exists? dest_sweeper_file
  STDERR.puts "No page_cache_sweeper found. Please remove the page_cache_sweeper script manually if it's still installed."
else
  File.delete dest_sweeper_file
  puts "Uninstallation successful. The page_cache_sweeper script has been removed from the script directory."
end  
