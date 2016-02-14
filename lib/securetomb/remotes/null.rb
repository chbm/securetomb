module Remotes

	# stub class for tests 
	class NULL
	
		def initialize(url)
		end

		def get_blob(id)
			File.open('/dev/null')
		end

		def put_blob(id)
			File.open('/dev/null', 'w')
		end

		def get
			File.open('/dev/null')
		end

		def put
			File.open('/dev/null', 'w')
		end
	end

end
