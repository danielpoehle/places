class Photo

	attr_accessor :id, :location
	attr_writer :contents

	def place
		#@place.nil? ? nil : Place.find(@place)
		Place.find(@place.nil? ? nil : @place)
	end

	def place=(new_place)
		case
		when new_place.is_a?(Place)
			@place=BSON::ObjectId.from_string(new_place.id)
		when new_place.is_a?(String)
			@place = BSON::ObjectId.from_string(new_place)
		when new_place.is_a?(BSON::ObjectId)
			@place = new_place
		end
	end


	def self.mongo_client
		Mongoid::Clients.default
	end

	def persisted?
		!@id.nil?
	end

	def initialize(params={})
	   if params[:_id]  #hash came from GridFS
	   	 @id=params[:_id].to_s
	   	 @location=params[:metadata][:location].nil? ? nil : Point.new(params[:metadata][:location])
	   	 @place =  params[:metadata][:place].nil? ? nil : BSON::ObjectId.from_string(params[:metadata][:place])
       else              #assume hash came from Rails
         @id=params[:id]
         @location=params[:location].nil? ? nil : params[:location]
         @place=params[:place].nil? ? nil : params[:place]
       end
    end

    def self.all(offset = 0, limit = nil)
    	result = mongo_client.database.fs.find.skip(offset)
    	result = result.limit(limit) if !limit.nil?
    	result.map {|doc| Photo.new(doc) }
    end

    def self.find id
    	id = BSON::ObjectId.from_string(id)
    	f = mongo_client.database.fs.find(:_id => id).first
    	return f.nil? ? nil : Photo.new(f)
    end

    def contents
        f = self.class.mongo_client.database.fs.find_one(:_id => BSON::ObjectId.from_string(@id))
        if f 
        	buffer = ""
        	f.chunks.reduce([]) do |x,chunk|
        		buffer << chunk.data.data
        	end
        	return buffer
        end 
    end

    def save
    	if persisted?
    			id = BSON::ObjectId.from_string(self.id)
    			#puts "#{id}"
    			#puts "#{self.location.to_hash}"
    			od = self.class.mongo_client.database.fs.find({:_id => id}).update_one('$set' => {"metadata.location" => self.location.to_hash,
    																							  "metadata.place" => BSON::ObjectId.from_string(self.place.id)})
    	else
    		if @contents
    			gps=EXIFR::JPEG.new(@contents).gps
    		    @location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)
    		    @contents.rewind
    		    description = {}
    		    description[:content_type] = "image/jpeg"
    		    description[:metadata] = {}
    		    description[:metadata][:location] = @location.to_hash
    		    grid_file = Mongo::Grid::File.new(@contents.read, description)
    		    id=self.class.mongo_client.database.fs.insert_one(grid_file)
    		    @id=id.to_s    
    		end		
    	end    	
    end

    def destroy
    	self.class.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(@id)).delete_one
    end

    def find_nearest_place_id(max_dist)
    	pl = Place.to_places(Place.near(@location, max_dist).limit(1)).first
    	
    	return pl.nil? ? nil : BSON::ObjectId.from_string(pl.id)
    end

    def self.find_photos_for_place place_id
    	place_id = BSON::ObjectId.from_string(place_id)
    	f = mongo_client.database.fs.find("metadata.place" => place_id)
    end

end