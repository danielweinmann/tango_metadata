#coding: utf-8

module TangoInfo

  class Performance

    require 'httparty'
    require 'nokogiri'
    require 'unicode_utils'
    require 'brstring'
    
    ROOT_URL = "https://tango.info"
    
    attr_accessor :orchestra, :title, :vocalist, :year, :tint, :genre, :date, :composer, :lyricist

    def initialize(options = {})
      @tint = options[:tint]
      @orchestra = options[:orchestra]
      @title = options[:title]
      @vocalist = options[:vocalist]
      @year = options[:year]
      @genre = options[:genre]
      @date = options[:date]
      @composer = options[:composer]
      @lyricist = options[:lyricist]
    end
    
    def instrumental
      !self.vocalist
    end
    
    def album
      (self.instrumental ? "Instrumental" : self.vocalist)
    end
    
    def get_info!
      get_tint_and_composers! unless self.tint
      if self.tint
        print "TINT #{self.tint} found. Retrieving data..."
        get_info_from_tango_info!
      else
        print "TINT not found. Searching Tango-DJ.at..."
        get_info_from_tango_dj_at!
      end
    end
    
    private
    
    def cleanup_string(string)
      UnicodeUtils.casefold(UnicodeUtils.nfkc(string)).remover_acentos
    end
    
    def compare_strings(first, second)
      cleanup_string(first) == cleanup_string(second)
    end
    
    def get_tint_and_composers!

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
        if compare_strings(title, self.title) or compare_strings(alternative_title, self.title)
          row.search('a').each do |link|
            if link.text == "info"
              works_data << { url: "#{ROOT_URL}#{link['href']}", composer: composer, lyricist: lyricist }
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
          year = row.search("td")[4].text[0..3]
          if compare_strings(orchestra, self.orchestra) and compare_strings(vocalist, self.vocalist) and compare_strings(year, self.year)
            row.search('a').each do |tint_link|
              if tint_link.text == "info"
                self.tint = tint_link['href'][1..-1]
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
      page = Nokogiri::HTML(HTTParty.get("#{ROOT_URL}/#{self.tint}").body)
      self.title = page.search(".content_inner h1")[0].text[7..-1]
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
      page = Nokogiri::HTML(HTTParty.get("http://www.tango-dj.at/database/?tango-db-search=#{URI.encode(cleanup_string(self.title))}&search=Search").body)
      page.search("#searchresult tbody tr").each do |row|
        title = row.search("td")[1].text
        orchestra = row.search("td")[2].text
        year = row.search("td")[3].text
        genre = UnicodeUtils.titlecase(row.search("td")[4].text)
        full_orchestra = "Orquesta #{self.orchestra}"
        full_orchestra = "#{full_orchestra} con #{self.vocalist}" if self.vocalist
        if compare_strings(title, self.title) and compare_strings(orchestra, full_orchestra) and compare_strings(year, self.year)
          self.genre = genre
          puts "found it! :D"
          return
        end
      end
      
      puts "nope :("

    end

  end

end