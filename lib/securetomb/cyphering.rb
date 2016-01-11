require 'filter_io'

module SecureTomb

	class Cyphering
		class UnknownCypher < RuntimeError
		end
		class CypherFailed < RuntimeError
		end


		def initialize(suite, *params)

			begin 
				require './lib/securetomb/cyphers/' + suite
			rescue LoadError
				raise UnknownCypher
			end

			begin
				@cypher = Object.const_get('Cyphers::' + suite.upcase).new(params)
			rescue
				raise CypherFailed
			end

		end

		def encrypt(input)
			@cypher.start_encrypting
			FilterIO.new input do |data, state|
				@cypher.process(data, state)
			end
		end

		def decrypt(input)
			@cypher.start_decrypting
			FilterIO.new input do |data, state|
				@cypher.process(data, state)
			end
		end	
	end
end

