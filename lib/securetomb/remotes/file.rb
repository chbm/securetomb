require 'uri'

module Remotes

	# stub class for tests 
	class FILE
	
		def initialize(uri)
			@uri = uri
			@basePath = uri.path
		end

		def getBlob(id)
			File.open(@basePath + '/blobs/' + id, 'rb')
		end

		def putBlob(id, input)
			File.copy_stream(input, File.open(@basePath + '/blobs/' + id, 'wb'))
		end

		def getFileset
			File.open(@basePath + '/fileset', 'rb')
		end

		def putFileset(input)
			File.copy_stream(input, File.open(@basePath + '/fileset', 'wb'))
		end

	end

end
