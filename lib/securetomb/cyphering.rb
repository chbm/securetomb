require 'filter_io'

module SecureTomb

	class Cyphering
		class UnknownCypher < RuntimeError
		end
		class CypherFailed < RuntimeError
		end


		def initialize(decrypt, input, suite, *params)

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

			@input = input
			@encrypt = (not decrypt)
			@outstream = FilterIO.new @input do |data, state|
				if @encrypt then
					@cypher.encrypt data
				else 
					@cypher.decrypt data
				end
			end
		end
		attr_reader :outstream
	end

end

