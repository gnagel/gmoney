require File.join(File.dirname(__FILE__), '/spec_helper')

describe GMoney::Transaction do
  before(:all) do
    @goog_feed = File.read('spec/fixtures/transactions_feed_for_GOOG.xml')
    @goog_feed_1 = File.read('spec/fixtures/transaction_feed_for_GOOG_1.xml')
  end
  
  before(:each) do
    @url = 'https://finance.google.com/finance/feeds/default/portfolios/9/positions/NASDAQ:GOOG/transactions' 
    @transaction_id = '9/NASDAQ:GOOG'
    
    @gf_request = GMoney::GFRequest.new(@url)
    @gf_request.method = :get   
    
    @gf_response = GMoney::GFResponse.new
    @gf_response.status_code = 200
    @gf_response.body = @goog_feed
  end
  
  it "should return all Tranasactions when the status code is 200" do
    transactions = transaction_helper(@transaction_id)
  
    transactions.size.should be_eql(4)
    transactions[1].commission.should be_eql(12.75)
    transactions[1].notes.should be_eql('Buy some more Google.')
  end
  
  it "should raise an error when the status code is not 200" do
    @transaction_id += '/1'
    @gf_response.status_code = 404
    @gf_response.body = "No transaction exists with tid 1"
  
    lambda { transaction_helper(@transaction_id) }.should raise_error(GMoney::Transaction::TransactionRequestError, @gf_response.body)  
  end

  it "should return a specific transactions if the user request a specific transaction" do
    @transaction_id += '/2'
    @gf_response.body = @goog_feed_1
    transaction = transaction_helper(@transaction_id)
  
    transaction.commission.should be_eql(50.0)
    transaction.price.should be_eql(400.0)
  end    
  
  def transaction_helper(id, options={})
    GMoney::GFSession.should_receive(:auth_token).and_return('toke')

    url = "#{GMoney::GF_PORTFOLIO_FEED_URL}/#{id.portfolio_id}/positions/#{id.position_id}/transactions/#{id.transaction_id}"

    GMoney::GFRequest.should_receive(:new).with(url, :headers => {"Authorization" => "GoogleLogin auth=toke"}).and_return(@gf_request)

    GMoney::GFService.should_receive(:send_request).with(@gf_request).and_return(@gf_response)
    
    GMoney::Transaction.find(id, options)
  end
end
