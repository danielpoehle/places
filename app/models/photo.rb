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
    
       #@chunkSize=params[:chunkSize]
       #@uploadDate=params[:uploadDate]
       #@contentType=params[:contentType]
       #@filename=params[:filename]
       #@length=params[:length]
       #@md5=params[:md5]
       #@contents=params[:contents]
    end

end