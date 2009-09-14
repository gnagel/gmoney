module GMoney
  class GFRequest
    attr_accessor :url, :body, :method, :headers
    
    def initialize(url, options = {})
      @url = url
      options.each do |key, value|
        self.send("#{key}=", value)
      end
      
      @method ||= :get
      @headers ||= {}
    end    
  end 
end
