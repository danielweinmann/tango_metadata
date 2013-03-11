# coding: utf-8

require File.expand_path("../lib/tango_info", __FILE__)

@main_folder = ARGV[0]
raise "Main folder not found" unless File.directory?(@main_folder)

Dir.foreach(@main_folder) do |folder|
  next if folder == '.' or folder == '..' or folder == '.DS_Store'
  Dir.foreach("#{@main_folder}/#{folder}") do |file|
    # TODO: remove this
    next unless file.match /esquina/
    next if file == '.' or file == '..' or file == '.DS_Store'
    parsed_file = file.match(/\A(\d{4})\s((.+)\s\((.+)\)|.+)\.(\S{3})\z/)
    @orchestra = folder
    @year = parsed_file[1]
    @vocalist = parsed_file[4]
    @name = parsed_file[(@vocalist ? 3 : 2)]
    @performance = TangoInfo::Performance.new orchestra: @orchestra, name: @name, vocalist: @vocalist, year: @year
    @performance.get_info!
  end
end

# IMPORTANT ffmpeg command for latter on
# ffmpeg -i in.m4a -acodec copy -metadata title="My Title" in.m4a
