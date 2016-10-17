class Point

	attr_accessor :latitude, :longitude

	def initialize(params={})
		@longitude = params[:lng] if !params[:lng].nil?
		@longitude = params[:coordinates][0] if !params[:coordinates].nil?
		@latitude = params[:lat] if !params[:lat].nil?
		@latitude = params[:coordinates][1] if !params[:coordinates].nil?
	end

	def to_hash
		{"type":"Point", "coordinates":[ @longitude, @latitude]}
	end

end