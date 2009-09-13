module GMoney
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
  end
end
