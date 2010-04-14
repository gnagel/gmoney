module GMoney

	# = GFSession
	#
	# Holds the authenicated user's token which is need
	# for each request sent to Google
	#
  class GFSession
    
    def self.login(email, password, opts={})
      @email = email
      auth_request = GMoney::AuthenticationRequest.new(email, password)
      @auth_token = auth_request.auth_token(opts)
    end

    def self.auth_token
      @auth_token
    end

    def self.email
      @email
    end
    
    def self.logout
      @email = nil
      @auth_token = nil
    end    
  end
end
