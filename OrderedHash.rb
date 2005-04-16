
class OrderedHash < Hash
  
  def initialize(default=nil)
    super(default)
    @order = []
  end

  def []=(key,val)
    @order.delete(key)
    @order.push(key)
    super(key,val)
  end

  def keys
    @order
  end

  def each
    @order.each do |key|
      yield(key, self[key])
    end
  end

  def each_key
    @order.each do |key|
      yield(key)
    end
  end

  def each_value
    @order.each do |key|
      yield(self[key])
    end
  end

end
