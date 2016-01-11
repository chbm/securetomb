module Cyphers
	# null class for tests
	class CLEAR
		def initialize(*params)
		end

		def start_encrypting
		end
		def start_decrypting
		end

		def process(data, state)
			data
		end
	end
end

