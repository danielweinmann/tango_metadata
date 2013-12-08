# coding: utf-8

require 'mp3info'
require 'unicode_utils'
require File.expand_path("../lib/tango_info", __FILE__)

@main_folder = ARGV[0]
raise "Main folder not found" unless File.directory?(@main_folder)

Dir.foreach(@main_folder) do |folder|
  next if folder == '.' or folder == '..' or folder == '.DS_Store'
  Dir.foreach("#{@main_folder}/#{folder}") do |file|
    
    # Comment the following line: useful only for DEBUG
    # next unless file.match /Se fue/
    
    next if file == '.' or file == '..' or file == '.DS_Store'
    parsed_file = file.match(/\A(\d{4})\s((.+)\s\((.+)\)|.+)\.(\S{3})\z/)
    next unless parsed_file
    @orchestra = folder
    @year = parsed_file[1]
    @vocalist = parsed_file[4]
    @title = parsed_file[(@vocalist ? 3 : 2)]
    @extention = parsed_file[5]
    @path = "#{@main_folder}/#{folder}"
    @file = file
    @shell_path = "#{@main_folder}/#{folder}".gsub("'", "\\\\'").gsub(" ", "\\ ").gsub("(", "\\\(").gsub(")", "\\\)")
    @shell_file = @file.gsub("'", "\\\\'").gsub(" ", "\\ ").gsub("(", "\\\(").gsub(")", "\\\)")
    @performance = TangoInfo::Performance.new orchestra: @orchestra, title: @title, vocalist: @vocalist, year: @year
    @performance.get_info!
    if UnicodeUtils.casefold(@extention) == UnicodeUtils.casefold("mp3")
      Mp3Info.open("#{@path}/#{@file}") do |mp3|
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
      `#{File.expand_path("../", __FILE__)}/ffmpeg -y -i #{@shell_path}/#{@shell_file} -map 0:a:0 -map_metadata -1 -c:a copy #{@shell_path}/clean_#{@shell_file} > /dev/null 2>&1`
      `#{File.expand_path("../", __FILE__)}/ffmpeg -y -i #{@shell_path}/clean_#{@shell_file} -map 0:a:0 -c:a copy -metadata title="#{@performance.titles}" -metadata artist='#{@performance.orchestra}' -metadata date='#{@performance.date}' -metadata album='#{@performance.album}' -metadata genre='#{@performance.genre}' -metadata composer='#{@performance.composers}' -metadata comment='#{@performance.comment}' #{@shell_path}/temp_#{@shell_file} > /dev/null 2>&1`
      if File.exists?("#{@path}/clean_#{@file}")
        File.delete("#{@path}/clean_#{@file}")
      end
      if File.exists?("#{@path}/temp_#{@file}")
        File.delete("#{@path}/#{@file}")
        File.rename("#{@path}/temp_#{@file}", "#{@path}/#{@file}")
      end
    end
  end
end
