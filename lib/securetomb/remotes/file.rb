require 'uri'
require 'securerandom'

module Remotes

	# stub class for tests 
	class FILE
	
		def initialize(uri)
			@uri = uri
			@basePath = uri.path
			begin
				Dir.mkdir(@basePath + '/blobs')
			rescue
			end
			if not Dir.exist?(@basePath + '/blobs') then
				raise RuntimeError
			end
		end

		def getBlob(id)
			File.open(@basePath + '/blobs/' + id, 'rb')
		end

		def putBlob(input)
			id = SecureRandom.uuid
			File.copy_stream(input, File.open(@basePath + '/blobs/' + id, 'wb'))
			[id]
		end

		def get(name)
			File.open(@basePath + '/' + name, 'rb')
		end

		def put(name, input)
			File.copy_stream(input, File.open(@basePath + '/' + name, 'wb'))
		end

	end

end
