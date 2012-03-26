module WebsocketRails
  class DataStore
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
    
    def cid
      @base.client_id
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