require 'json'
require 'net/http'

module Geogov

  def get(url)
    url = URI.parse(url) unless url.is_a? URI
    response = Net::HTTP.start(url.host, url.port) { |http|
      request = Net::HTTP::Get.new(url.request_uri)
      http.request(request)
    }
    return nil if response.code != '200'
    return response.body
  end

  def get_json(url)
    response = self.get(url)
    if response
      return JSON.parse(response)
    else
      return nil
    end
  end

  def hash_to_params(hash)
    hash.map { |k,v| CGI.escape(k.to_s) + "=" + CGI.escape(v.to_s) }.join("&")
  end

  # Dead simple and inefficient LRU cache
  # In no way thread-safe
    class LruCache

      def initialize(size = 100)
        @size = size
        @bucket1 = {}
        @bucket2 = {}
      end

      def []=(key,obj)
        if @bucket1[key]
          @bucket1[key] = obj
        elsif @bucket2[key]
          @bucket2[key] = obj
        else
          @bucket1[key] = obj
          swizzle if @bucket1.size > @size
        end
      end

      def [](key)
        if @bucket1[key]
          return @bucket1[key]
        elsif @bucket2[key]
          obj = @bucket2.delete[key]
          @bucket1[key] = obj
          swizzle if @bucket1.size > @size
          return obj
        end
      end

      def swizzle
        @bucket2 = @bucket1
        @bucket1 = {}
      end
    end

    class SimpleCache
      def initialize(delegate)
        @delegate = delegate
        @cache = LruCache.new(1000)
      end

      def method_missing(m, *args)
        arg_key = args.inspect
        cache_key = "#{m}--#{arg_key}"
        if @cache[cache_key]
          return @cache[cache_key]
        else
          result = @delegate.send(m,*args)
          @cache[cache_key] = result
          return result
        end
      end
    end


end
