class AddressComponent

	attr_reader :long_name, :short_name, :types
	

	def initialize(params={})
		@long_name = params[:long_name] if !params[:long_name].nil?
		@short_name = params[:short_name] if !params[:short_name].nil?
		@types = params[:types] if !params[:types].nil?
	end
end