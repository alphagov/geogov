module Geogov

  class Google
    
    def dimension(l1,l2)
      "#{l1}x#{l2}"
    end    

    def location(l1,l2)
      "#{l1},#{l2}"
    end

    def map_img(lat,lon,options= {})
      g_options = {
        :zoom => options[:z] || 14,
        :size => dimension(options[:w],options[:h]),
        :center => location(lat,lon),
        :sensor => false
      }
      if options[:marker_lat] && options[:marker_lon]
        location = location(options[:marker_lat],options[:marker_lon])
        g_options[:markers] = ["color:blue",location].join("|") 
      end
      
      params = Geogov.hash_to_params(g_options)

      "http://maps.google.com/maps/api/staticmap?#{params}"
    end


    def map_href(lat,lon,options = {})
      g_options = {
        :z => options[:z] || 14,
        :ie => "UTF8",
        :q  => location(lat,lon)  
      }
      if options[:marker_lat] && options[:marker_lon]
        location = location(options[:marker_lat],options[:marker_lon])
        g_options[:sll] = location 
      end

      params = Geogov.hash_to_params(g_options)
      "http://maps.google.com/maps?#{params}"
    end

  end

end
