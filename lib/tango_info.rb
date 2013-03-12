#coding: utf-8

module TangoInfo

  class Performance

    require 'httparty'
    require 'nokogiri'
    require 'unicode_utils'
    require 'brstring'
    
    ROOT_URL = "https://tango.info"
    
    attr_accessor :orchestra, :name, :vocalist, :year, :tint, :genre, :date

    def initialize(options = {})
      @tint = options[:tint]
      @orchestra = options[:orchestra]
      @name = options[:name]
      @vocalist = options[:vocalist]
      @year = options[:year]
      @genre = options[:genre]
      @date = options[:date]
    end
    
    def instrumental
      !self.vocalist
    end
    
    def get_info!
      self.tint = get_tint unless self.tint
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
    
    def get_tint

      page = Nokogiri::HTML(HTTParty.get("#{ROOT_URL}/?q=#{URI.encode(cleanup_string(self.name))}").body)
      works_header = nil
      page.search("h3").each do |header|
        if header.content.match /Works/
          works_header = header
          break
        end
      end
      return unless works_header

      links = []
      works_header.next_element.search("tbody").search("tr").each do |row|
        name = row.search("td")[0].text
        alternative_name = row.search("td")[1].text
        if compare_strings(name, self.name) or compare_strings(alternative_name, self.name)
          row.search('a').each do |link|
            if link.text == "info"
              links << "#{ROOT_URL}#{link['href']}"
            end
          end
        end
      end
      
      links.each do |link|

        performances_header = nil
        page = Nokogiri::HTML(HTTParty.get(link).body)
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
                return tint_link['href'][1..-1]
              end
            end
          end
        end

      end
      
      nil
      
    end
    
    def get_info_from_tango_info!
      page = Nokogiri::HTML(HTTParty.get("#{ROOT_URL}/#{self.tint}").body)
      self.name = page.search(".content_inner h1")[0].text[7..-1]
      page.search(".infobox td").each do |column|
        if column.text == "Genre:"
          self.genre = column.next_element.text
        elsif column.text == "Date:"
          self.date = column.next_element.text
          break
        end
      end
      puts "OK"
    end
    
    def get_info_from_tango_dj_at!
      page = Nokogiri::HTML(HTTParty.get("http://www.tango-dj.at/database/?tango-db-search=#{URI.encode(cleanup_string(self.name))}&search=Search").body)
      page.search("#searchresult tbody tr").each do |row|
        name = row.search("td")[1].text
        orchestra = row.search("td")[2].text
        year = row.search("td")[3].text
        genre = UnicodeUtils.downcase(row.search("td")[4].text)
        full_orchestra = "Orquesta #{self.orchestra}"
        full_orchestra = "#{full_orchestra} con #{self.vocalist}" if self.vocalist
        if compare_strings(name, self.name) and compare_strings(orchestra, full_orchestra) and compare_strings(year, self.year)
          self.genre = genre
          puts "found it! :D"
          return
        end
      end
      
      puts "nope :("

    end

  end

end