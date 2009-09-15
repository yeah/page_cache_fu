require 'ftools'

# Install page_cache_sweeper into the local script directory.
#
# If page_cache_sweeper already exists, print a warning and exit.
#
if File.directory? "script"
  dest_dir = "script"
end

src_sweeper_file = File.join(File.dirname(__FILE__),"script/page_cache_sweeper")
dest_sweeper_file = File.join(dest_dir, "page_cache_sweeper") if dest_dir

if !dest_dir
  STDERR.puts "Could not find a script directory. Please install the page_cache_sweeper script manually."
elsif File::exists? dest_sweeper_file
  STDERR.puts "You already have page_cache_sweeper installed at #{dest_sweeper_file}."
else
  File.copy src_sweeper_file, dest_sweeper_file
  puts "Installation successful. The page_cache_sweeper script has been installed into #{dest_sweeper_file}."
end  
