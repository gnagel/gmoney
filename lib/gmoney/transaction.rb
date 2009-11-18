module GMoney
  class Transaction
    class TransactionRequestError < StandardError; end
    class TransactionDeleteError < StandardError;end    
    class TransactionSaveError < StandardError;end
    
    attr_reader :id, :updated, :title
    attr_accessor :type, :date, :shares, :notes, :commission, :price, :portfolio, :ticker, :currency_code
    
    def self.find(id, options={})   
      find_by_url("#{GF_PORTFOLIO_FEED_URL}/#{id.portfolio_id}/positions/#{id.position_id}/transactions/#{id.transaction_id}", options)    
    end    
    
    def save
      save_transaction
    end    
    
    def self.delete(id)
      delete_transaction(id)
    end
    
    def delete
      Transaction.delete(@id.transaction_feed_id)
      freeze
    end    
    
    def self.find_by_url(url, options={})
      transactions = []
      
      response = GFService.send_request(GFRequest.new(url, :headers => {"Authorization" => "GoogleLogin auth=#{GFSession.auth_token}"}))
      
      if response.status_code == HTTPOK
        transactions = TransactionFeedParser.parse_transaction_feed(response.body)
      else
        raise TransactionRequestError, response.body
      end
      
      return transactions[0] if transactions.size == 1
      
      transactions
    end  
    
    #If you are working behind some firewalls DELETE HTTP request won't work.
    #To overcome this problem the google doc say to use a post request with
    #the X-HTTP-Method-Override set to "DELETE"
    def self.delete_transaction(id)    
      url = "#{GF_PORTFOLIO_FEED_URL}/#{id.portfolio_id}/positions/#{id.position_id}/transactions/#{id.transaction_id}"
      response = GFService.send_request(GFRequest.new(url, :method => :post, :headers => {"Authorization" => "GoogleLogin auth=#{GFSession.auth_token}", "X-HTTP-Method-Override" => "DELETE"}))
      raise TransactionDeleteError, response.body if response.status_code != HTTPOK
    end
    
    def save_transaction
      raise TransactionSaveError, "You must include a portfolio id, ticker symbol, and transaction type ['Buy', 'Sell', 'Buy to Cover', 'Sell Short'] in order to create a transaction." if !is_valid_transaction?
    
      @currency_code ||= 'USD'
      @date ||= Time.now.strftime("%Y-%m-%dT%H:%M:%S.000")
      @shares ||= 0     
     
      atom_string = "<?xml version='1.0'?>
      <entry xmlns='http://www.w3.org/2005/Atom'
            xmlns:gf='http://schemas.google.com/finance/2007'
            xmlns:gd='http://schemas.google.com/g/2005'>
            <gf:transactionData date='#{@date}' shares='#{@shares}' type='#{@type}'>"
                              
      atom_string += "<gf:commission><gd:money amount='#{@commission}' currencyCode='#{@currency_code}'/></gf:commission>" if @commission
      atom_string += "<gf:price><gd:money amount='#{@price}' currencyCode='#{@currency_code}'/></gf:price>" if @price
      atom_string += "</gf:transactionData></entry>"
      
      url = @id ? @id : "#{GF_PORTFOLIO_FEED_URL}/#{@portfolio}/positions/#{@ticker}/transactions"
      
      #Some firewalls block HTTP PUT messages. To get around this, you can include a 
      #X-HTTP-Method-Override: PUT header in a POST request
      headers = {"Authorization" => "GoogleLogin auth=#{GFSession.auth_token}", "Content-Type" => "application/atom+xml"}
      headers["X-HTTP-Method-Override"] = "PUT" if @id #if there is already an @id defined then we are updating a transaction

      request = GFRequest.new(url, :method => :post, :body => atom_string, :headers => headers)
      
      response = GFService.send_request(request)

      if response.status_code == HTTPCreated || response.status_code == HTTPOK
        transaction = TransactionFeedParser.parse_transaction_feed(response.body)[0]
        self.instance_variable_set("@id", transaction.id) if response.status_code == HTTPCreated
        transaction.portfolio = @portfolio if response.status_code == HTTPCreated        
      else
        raise TransactionSaveError, response.body
      end
      transaction
    end
    
    def is_valid_transaction?
      !(@portfolio.to_s.blank? || @ticker.blank? || !is_valid_transaction_type?)
    end
    
    def is_valid_transaction_type?
      ['Buy', 'Sell', 'Buy to Cover', 'Sell Short'].include?(@type)
    end
    
    private :save_transaction, :is_valid_transaction?, :is_valid_transaction_type?
    private_class_method :find_by_url, :delete_transaction
  end
end
