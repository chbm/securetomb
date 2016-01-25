module Cyphers
	# null class for tests
	class CLEAR
		class Worker
			def initialize(*params)
			end

			def process(data, state)
				data
			end
		end

		def initialize(*params)
		end
		def make_worker_to_decrypt
			Worker.new()
		end
		def make_worker_to_encrypt
			Worker.new()
		end
	end
end

