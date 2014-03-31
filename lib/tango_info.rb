#coding: utf-8

module TangoInfo

  class Performance

    require 'httparty'
    require 'nokogiri'
    require 'unicode_utils'
    require 'brstring'
    
    ROOT_URL = "https://tango.info"
    
    attr_accessor :orchestra, :title, :alternative_title, :vocalist, :year, :tint, :genre, :composer, :lyricist, :not_found

    def initialize(options = {})
      @tint = options[:tint]
      @orchestra = UnicodeUtils.nfkc(options[:orchestra]) if options[:orchestra]
      @title = UnicodeUtils.nfkc(options[:title]) if options[:title]
      @vocalist = UnicodeUtils.nfkc(options[:vocalist]) if options[:vocalist]
      @year = options[:year]
      @genre = UnicodeUtils.nfkc(options[:genre]) if options[:genre]
      @date = options[:date]
      @composer = UnicodeUtils.nfkc(options[:composer]) if options[:composer]
      @lyricist = UnicodeUtils.nfkc(options[:lyricist]) if options[:lyricist]
      @not_found = false
    end
    
    def instrumental
      !self.vocalist
    end
    
    def album
      (self.instrumental ? "Instrumental" : self.vocalist)
    end
    
    def date=(value)
      @date = value
    end
    
    def date
      @date or "#{self.year}-01-01"
    end

    def composers
      composers = []
      composers << "Composer: #{self.composer}" if self.composer and not self.composer.empty?
      composers << "Lyricist: #{self.lyricist}" if self.lyricist and not self.lyricist.empty?
      composers.join("; ")
    end
    
    def titles
      "#{self.title}#{" | #{self.alternative_title}" if self.alternative_title and not self.alternative_title.empty?}"
    end
    
    def comment
      if self.not_found
        "*** Info not found. Please review file ***"
      else
        self.composers
      end
    end
    
    def url
      "#{ROOT_URL}/#{self.tint}" if self.tint
    end
    
    def get_info!
      puts "#{self.orchestra} - #{self.year} #{self.title} (#{self.album})"      
      get_tint_and_initial_info!
      if self.tint
        print "  TINT #{self.tint} found. Retrieving info..."
        get_info_from_tango_info!
      else
        print "  TINT not found. Searching Tango-DJ.at..."
        get_info_from_tango_dj_at!
      end
    end
    
    private
    
    def cleanup_string(string, remove_non_word_characters = true)
      return unless string
      clean_string = UnicodeUtils.casefold(UnicodeUtils.nfkc(string)).remover_acentos
      clean_string.gsub!(/\W+/, ' ') if remove_non_word_characters
      clean_string.gsub(/\s+/, ' ').strip
    end
    
    def compare_strings(first, second)
      cleanup_string(first) == cleanup_string(second)
    end
    
    def get_tint_and_initial_info!

      page = Nokogiri::HTML(HTTParty.get("#{ROOT_URL}/?q=#{URI.encode(cleanup_string(self.title))}").body)
      works_header = nil
      page.search("h3").each do |header|
        if header.content.match /Works/
          works_header = header
          break
        end
      end
      return unless works_header

      works_data = []
      works_header.next_element.search("tbody").search("tr").each do |row|
        title = row.search("td")[0].text
        alternative_title = row.search("td")[1].text
        composer = row.search("td")[3].text
        lyricist = row.search("td")[4].text
        composer = nil if composer == "-"
        lyricist = nil if lyricist == "-"
        if compare_strings(title, self.title) or compare_strings(alternative_title, self.title)
          row.search('a').each do |link|
            if link.text == "info"
              works_data << { url: "#{ROOT_URL}#{link['href']}", title: title, alternative_title: alternative_title, composer: composer, lyricist: lyricist }
            end
          end
        end
      end
      
      works_data.each do |work_data|

        performances_header = nil
        page = Nokogiri::HTML(HTTParty.get(work_data[:url]).body)
        page.search("h2").each do |header|
          if header.content.match /Performances/
            performances_header = header
          end
        end
        return unless performances_header
        next if performances_header.next_sibling.content.match /\AN\/A/
        performances_header.next_sibling.search("tbody").search("tr").each do |row|
          orchestra = row.search("td")[2].text
          vocalist = row.search("td")[3].text
          vocalist = nil if vocalist == "-"
          year = row.search("td")[4].text[0..3]
          if compare_strings(orchestra, self.orchestra) and compare_strings(vocalist, self.vocalist) and compare_strings(year, self.year)
            row.search('a').each do |tint_link|
              if tint_link.text == "info"
                self.tint = tint_link['href'][1..-1]
                self.title = work_data[:title]
                self.alternative_title = work_data[:alternative_title]
                self.orchestra = orchestra
                self.vocalist = vocalist
                self.composer = work_data[:composer]
                self.lyricist = work_data[:lyricist]
                return
              end
            end
          end
        end

      end
      
      self.tint = nil
      
    end
    
    def get_info_from_tango_info!
      page = Nokogiri::HTML(HTTParty.get(self.url).body)
      page.search(".infobox td").each do |column|
        if column.text == "Genre:"
          self.genre = UnicodeUtils.titlecase(column.next_element.text)
        elsif column.text == "Date:"
          self.date = column.next_element.text
          break
        end
      end
      puts "OK"
    end
    
    def get_info_from_tango_dj_at!
      [self.title, self.alternative_title].each do |search|
        next unless search
        page = Nokogiri::HTML(HTTParty.get("http://www.tango-dj.at/database/?tango-db-search=#{URI.encode(cleanup_string(search, false))}&search=Search").body)
        page.search("#searchresult tbody tr").each do |row|
          title = row.search("td")[2].text
          orchestra = row.search("td")[3].text
          date = row.search("td")[4].text
          year = date[-4..-1]
          genre = UnicodeUtils.titlecase(row.search("td")[5].text)
          full_orchestra = "Orquesta #{self.orchestra}"
          full_orchestra = "#{full_orchestra} con #{self.vocalist.gsub(', ', ' y ')}" if self.vocalist
          # Workaround to solve 'José García y sus Zorros Grises', because in Tango.info it is registered only as 'José García' and in TangoDJ.at it is registered as 'José García y su Orquesta "Los Zorros Grises"'
          full_orchestra2 = "#{self.orchestra} y su Orquesta \"Los Zorros Grises\""
          full_orchestra2 = "#{full_orchestra2} con #{self.vocalist.gsub(', ', ' y ')}" if self.vocalist
          if compare_strings(title, search) and compare_strings(year, self.year) and ((compare_strings(orchestra, full_orchestra)) or (compare_strings(orchestra, full_orchestra2)))
            self.genre = genre
            self.date = "#{date[-4..-1]}-#{date[-7..-6]}-#{date[-10..-9]}" if date.length > 4
            if self.vocalist
              self.orchestra = orchestra.match(/\AOrquesta\s(.+)\scon/)[1] rescue orchestra.match(/(.+)\sy su Orquesta/)[1]
              self.vocalist = orchestra.match(/\scon\s(.+)/)[1].gsub(' y ', ', ')
            else
              self.orchestra = orchestra.match(/\AOrquesta\s(.+)/)[1] rescue orchestra.match(/(.+)\sy su Orquesta/)[1]
            end
            puts "found it! :D"
            return
          end
        end
      end
      
      self.not_found = true
      puts "nope :("

    end

  end

end