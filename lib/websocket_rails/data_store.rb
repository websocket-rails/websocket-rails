module WebsocketRails
  # Provides a convenient way to persist data between events on a per client basis. Since every
  # events from every client is executed on the same instance of the controller object, instance
  # variables defined in actions will be shared between clients. The {DataStore} provides a Hash
  # that is private for each connected client. It is accessed through a WebsocketRails controller
  # using the {BaseController.data_store} instance method.
  # 
  # = Example Usage
  # == Creating a user
  #   # action on ChatController called by :client_connected event
  #   def new_user
  #     # This would be overwritten when the next user joins
  #     @user = User.new( message[:user_name] )
  #     
  #     # This will remain private for each user
  #     data_store[:user] = User.new( message[:user_name] ) 
  #   end
  #
  # == Collecting all Users from the DataStore
  # Calling the {#each} method will yield the Hash for all connected clients:
  #   # From your controller
  #   all_users = []
  #   data_store.each { |store| all_users << store[:user] }
  # The {DataStore} also uses method_missing to provide a convenience for the above case. Calling
  # +data_store.each_<key>+ from a controller where +<key>+ is the hash key that you wish to collect
  # will return an Array of the values for each connected client.
  #   # From your controller, assuming two users have already connected
  #   data_store[:user] = UserThree
  #   data_store.each_user
  #   => [UserOne,UserTwo,UserThree]
  class DataStore
    
    extend Forwardable
    
    def_delegator :@base, :client_id, :cid
    
    def initialize(base_controller)
      @base = base_controller
      @data = Hash.new {|h,k| h[k] = Hash.new}
      @data = @data.with_indifferent_access
    end

    def []=(k,v)
      @data[cid] = Hash.new unless @data[cid]
      @data[cid][k] = v
    end

    def [](k)
      @data[cid][k] = Hash.new unless @data[cid]
      @data[cid][k]
    end

    def each(&block)
      @data.each do |cid,hash|
        block.call(hash) if block
      end
    end
    
    def remove_client
      @data.delete(cid)
    end
    
    def delete(key)
      @data[cid].delete(key)
    end
    
    def method_missing(method, *args, &block)
      if /each_(?<hash_key>\w*)/ =~ method
        results = []
        @data.each do |cid,hash|
          results << hash[hash_key]
        end
        results
      else
        super
      end
    end
  end
end