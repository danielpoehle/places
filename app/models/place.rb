class Place

	attr_accessor :id, :formatted_address, :location, :address_components

	def initialize(params={})
		@id = params[:_id].nil? ? params[:id] : params[:_id].to_s
		@formatted_address = params[:formatted_address] if !params[:formatted_address].nil?
		@location = Point.new(params[:geometry][:geolocation]) if !params[:geometry][:geolocation].nil?
		@address_components = params[:address_components].map do |addr|
			AddressComponent.new(addr)
		end if !params[:address_components].nil?

	end

	def self.mongo_client
		Mongoid::Clients.default
	end

	def self.collection
		self.mongo_client['places']
	end

	def self.load_all doc
		array = JSON.parse(File.read(doc))
		self.collection.insert_many(array)
	end

	def self.find_by_short_name name
		collection.find("address_components.short_name" => name)
	end

	def self.to_places collection_view
		collection_view.map do |view|
			Place.new(view)
		end
	end

	def self.find id
		id = BSON::ObjectId.from_string(id) if !id.nil? and id != ""
		result = self.collection.find(:_id => id).first
		return result.nil? ? nil : Place.new(result)
	end

	def self.all(offset=0, limit=nil)
		result = self.collection.find.skip(offset)
		result = result.limit(limit) if !limit.nil?
		result.map do |view|
			Place.new(view)
		end
	end

	def destroy
		id = BSON::ObjectId.from_string(@id)
		#puts id
		self.class.collection.delete_one(:_id => id)
	end

	def self.get_address_components(sort = {:_id => 1}, offset = 0, limit= 4611686018427387904)
		self.collection.find.aggregate([
			{:$sort => sort},
			{:$unwind => '$address_components'},
			{:$project => {:_id => 1, :address_components => 1, :formatted_address => 1, "geometry.geolocation" => 1}},
			{:$skip => offset},
			{:$limit => limit} ])
	end

	def self.get_country_names
		self.collection.find.aggregate([
			{:$unwind => '$address_components'},
			{:$project => {:_id =>0, "address_components.long_name" => 1, "address_components.types" => 1}},
			{:$match => {"address_components.types" => "country"}},
			{:$group => {:_id => "country", :countries => {:$addToSet => "$address_components.long_name"}}}
			]).to_a.map {|h| h[:countries]}.first
	end

	def self.find_ids_by_country_code code
		self.collection.find.aggregate([
			{:$match => {"address_components.short_name" => code}},
			{:$project => {:_id => 1}}
			]).map {|doc| doc[:_id].to_s}
	end

	def self.create_indexes
		self.collection.indexes.create_one({"geometry.geolocation" => Mongo::Index::GEO2DSPHERE})
	end

	def self.remove_indexes
		self.collection.indexes.drop_one("geometry.geolocation_2dsphere")
	end

	def self.near(point, max_m = 4611686018427387904)
		self.collection.find("geometry.geolocation" => { :$near => { :$geometry => point.to_hash, :$maxDistance => max_m}})
	end

	def near(max_m = 4611686018427387904)
		Place.to_places(Place.near(@location, max_m))
	end

	def photos(offset=0, limit=nil)
		result = Photo.find_photos_for_place(@id).skip(offset)
		result = result.limit(limit) if !limit.nil?
		result.map do |view|
			Photo.new(view)
		end
	end

end