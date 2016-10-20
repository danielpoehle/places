class Photo

	attr_accessor :id, :location
	attr_writer :contents

	def self.mongo_client
		Mongoid::Clients.default
	end

	def persisted?
		!@id.nil?
	end

	def initialize(params={})
	   if params[:_id]  #hash came from GridFS
	   	 @id=params[:_id].to_s
	   	 @location=params[:metadata].nil? ? nil : Point.new(params[:metadata][:location])
       else              #assume hash came from Rails
         @id=params[:id]
         @location=params[:location].nil? ? nil : params[:location]
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
    	if !persisted?
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
    	else
    		@id.to_s
    	end
    end

    def destroy
    	self.class.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(@id)).delete_one
    end

end