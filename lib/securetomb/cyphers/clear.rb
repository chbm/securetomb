module Cyphers
	# null class for tests
	class CLEAR
		def initialize(*params)
		end

		def encrypt(data)
			data
		end
		def decrypt(data)
			data
		end
	end
end

