module TangoInfo

  class Performance

    require 'httparty'
    require 'nokogiri'
    
    attr_accessor :orchestra, :name, :singer, :year

    def initialize(options = {})
      @orchestra = options[:orchestra]
      @name = options[:name]
      @singer = options[:singer]
      @year = options[:year]
    end
    
    def instrumental
      !self.singer
    end
    
    def get_info!
      # TODO: remove this
      self.name = "Se fue"
      
      page = Nokogiri::HTML(HTTParty.get("https://tango.info/?q=#{URI.encode(self.name)}").body)
      page.search("h3").each do |title|
        if title.content.match /Works/
          @works_title = title
          break
        end
      end
      
      return unless @works_title
      puts @works_title.next_element

    end

  end

end