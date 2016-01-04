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
			FilterIO.new input do |data, state|
				@cypher.encrypt data
			end
		end

		def decrypt(input)
			FilterIO.new input do |data, state|
				@cypher.decrypt data
			end
		end
		
	end
end

