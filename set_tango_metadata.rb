# coding: utf-8

require 'mp3info'
require File.expand_path("../lib/tango_info", __FILE__)

@main_folder = ARGV[0]
raise "Main folder not found" unless File.directory?(@main_folder)

Dir.foreach(@main_folder) do |folder|
  next if folder == '.' or folder == '..' or folder == '.DS_Store'
  Dir.foreach("#{@main_folder}/#{folder}") do |file|
    
    # Comment the following line: useful only for DEBUG
    # next unless file.match /La racha/
    
    next if file == '.' or file == '..' or file == '.DS_Store'
    parsed_file = file.match(/\A(\d{4})\s((.+)\s\((.+)\)|.+)\.(\S{3})\z/)
    next unless parsed_file
    @orchestra = folder
    @year = parsed_file[1]
    @vocalist = parsed_file[4]
    @title = parsed_file[(@vocalist ? 3 : 2)]
    @extention = parsed_file[5]
    @performance = TangoInfo::Performance.new orchestra: @orchestra, title: @title, vocalist: @vocalist, year: @year
    @performance.get_info!
    if @extention == "mp3"
      Mp3Info.open("#{@main_folder}/#{folder}/#{file}") do |mp3|
        mp3.tag1.clear
        mp3.tag1.title = @performance.titles
        mp3.tag1.artist = @performance.orchestra
        mp3.tag1.album = @performance.album
        mp3.tag1.year = @performance.year
        mp3.tag2.clear
        mp3.tag2.remove_pictures
        mp3.tag2.TIT2 = @performance.titles
        mp3.tag2.TDRL = @performance.date
        mp3.tag2.TDRC = @performance.date
        mp3.tag2.TALB = @performance.album
        mp3.tag2.TCON = @performance.genre
        mp3.tag2.TCOM = @performance.composers
        mp3.tag2.COMM = @performance.comment
      end
    else
      `#{File.expand_path("../", __FILE__)}/ffmpeg -y -i '#{@main_folder}/#{folder}/#{file}' -map 0:a:0 -map_metadata -1 -c:a copy '#{@main_folder}#{folder}/clean_#{file}' > /dev/null 2>&1`
      `#{File.expand_path("../", __FILE__)}/ffmpeg -y -i '#{@main_folder}/#{folder}/clean_#{file}' -map 0:a:0 -c:a copy -metadata title='#{@performance.titles}' -metadata artist='#{@performance.orchestra}' -metadata date='#{@performance.date}' -metadata album='#{@performance.album}' -metadata genre='#{@performance.genre}' -metadata composer='#{@performance.composers}' -metadata comment='#{@performance.comment}' '#{@main_folder}#{folder}/temp_#{file}' > /dev/null 2>&1`
      if File.exists?("#{@main_folder}/#{folder}/clean_#{file}")
        File.delete("#{@main_folder}/#{folder}/clean_#{file}")
      end
      if File.exists?("#{@main_folder}/#{folder}/temp_#{file}")
        File.delete("#{@main_folder}/#{folder}/#{file}")
        File.rename("#{@main_folder}/#{folder}/temp_#{file}", "#{@main_folder}/#{folder}/#{file}")
      end
    end
  end
end
