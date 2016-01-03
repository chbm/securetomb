module Remotes

	# stub class for tests 
	class NULL
	
		def initialize(url)
		end

		def getBlob(id)
			File.open('/dev/null')
		end

		def putBlob(id)
			File.open('/dev/null', 'w')
		end

		def getFileset
			File.open('/dev/null')
		end

		def putFileset
			File.open('/dev/null', 'w')
		end
	end

end
