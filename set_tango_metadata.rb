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
    `#{File.expand_path("../", __FILE__)}/ffmpeg -y -i '#{@main_folder}/#{folder}/#{file}' -map 0:a:0 -map_metadata -1 -c:a copy '#{@main_folder}#{folder}/clean_#{file}' > /dev/null 2>&1`
    `#{File.expand_path("../", __FILE__)}/ffmpeg -y -i '#{@main_folder}/#{folder}/clean_#{file}' -map 0:a:0 -c:a copy -metadata title='#{@performance.title}' -metadata artist='#{@performance.orchestra}' -metadata date='#{@performance.date}' -metadata TDRC='#{@performance.date}' -metadata label='#{@performance.year}' -metadata album='#{@performance.album}' -metadata genre='#{@performance.genre}' -metadata composer='#{@performance.composers}' '#{@main_folder}#{folder}/temp_#{file}' > /dev/null 2>&1`
    File.delete("#{@main_folder}/#{folder}/#{file}")
    File.delete("#{@main_folder}/#{folder}/clean_#{file}")
    File.rename("#{@main_folder}/#{folder}/temp_#{file}", "#{@main_folder}/#{folder}/#{file}")
  end
end
