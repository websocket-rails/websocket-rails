module WebsocketRails
  def self.stage?
    @stage
  end
  def self.stage=(val)
    @stage = val
  end
  class Stager
    def initialize app
      @app = app
      WebsocketRails.stage = (ENV['WS_STAGE'] == 1.to_s ? true : false) 
      #rotate route 
    end
    def call env
      @app.call(env)
    end
  end 
  class WtfHandler 
    def initialize
      
    end
  end
end