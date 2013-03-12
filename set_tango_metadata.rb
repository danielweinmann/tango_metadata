# coding: utf-8

require File.expand_path("../lib/tango_info", __FILE__)

@main_folder = ARGV[0]
raise "Main folder not found" unless File.directory?(@main_folder)

Dir.foreach(@main_folder) do |folder|
  next if folder == '.' or folder == '..' or folder == '.DS_Store'
  Dir.foreach("#{@main_folder}/#{folder}") do |file|
    next if file == '.' or file == '..' or file == '.DS_Store'
    parsed_file = file.match(/\A(\d{4})\s((.+)\s\((.+)\)|.+)\.(\S{3})\z/)
    next unless parsed_file
    @orchestra = folder
    @year = parsed_file[1]
    @vocalist = parsed_file[4]
    @title = parsed_file[(@vocalist ? 3 : 2)]
    @performance = TangoInfo::Performance.new orchestra: @orchestra, title: @title, vocalist: @vocalist, year: @year
    @performance.get_info!
    `ffmpeg -y -i '#{@main_folder}/#{folder}/#{file}' -acodec copy -metadata title='#{@performance.title}' -metadata artist='#{@performance.orchestra}' -metadata date='#{@performance.year}' -metadata TYER='#{@performance.year}' '#{@main_folder}#{folder}/temp_#{file}' > /dev/null 2>&1`
  end
end
