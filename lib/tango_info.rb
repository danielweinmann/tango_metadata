module TangoInfo

  class Performance

    require 'httparty'
    require 'nokogiri'
    require 'unicode_utils'
    
    ROOT_URL = "https://tango.info"
    
    attr_accessor :orchestra, :name, :vocalist, :year, :tint

    def initialize(options = {})
      @orchestra = options[:orchestra]
      @name = options[:name]
      @vocalist = options[:vocalist]
      @year = options[:year]
    end
    
    def instrumental
      !self.vocalist
    end
    
    def get_info!
      self.tint = get_tint
      puts self.tint
    end
    
    private
    
    def cleanup_string(string)
      UnicodeUtils.casefold(UnicodeUtils.nfkd(string))
    end
    
    def compare_strings(first, second)
      cleanup_string(first) == cleanup_string(second)
    end
    
    def get_tint

      page = Nokogiri::HTML(HTTParty.get("#{ROOT_URL}/?q=#{URI.encode(self.name)}").body)
      page.search("h3").each do |header|
        if header.content.match /Works/
          @works_header = header
          break
        end
      end
      return unless @works_header

      @links = []
      @works_header.next_element.search("tbody").search("tr").each do |row|
        name = row.search("td")[0].text
        alternative_name = row.search("td")[1].text
        if compare_strings(name, self.name) or compare_strings(alternative_name, self.name)
          row.search('a').each do |link|
            if link.text == "info"
              @links << "#{ROOT_URL}#{link['href']}"
            end
          end
        end
      end
      
      puts @links.inspect
      
      @links.each do |link|

        @performances_header = nil
        page = Nokogiri::HTML(HTTParty.get(link).body)
        page.search("h2").each do |header|
          if header.content.match /Performances/
            @performances_header = header
          end
        end
        return unless @performances_header
        next if @performances_header.next_sibling.content.match /\AN\/A/
        @performances_header.next_sibling.search("tbody").search("tr").each do |row|
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

  end

end