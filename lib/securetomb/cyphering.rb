require 'filter_io'
require "openssl"


module SecureTomb

	class Cyphering
		class UnknownCypher < RuntimeError
		end
		class CypherFailed < RuntimeError
		end

		def self.randombytes
			OpenSSL::Random.random_bytes(32)
		end

		def initialize(seed, suite, *params)

			begin 
				require './lib/securetomb/cyphers/' + suite
			rescue LoadError
				raise UnknownCypher
			end

			begin
				@cypher = Object.const_get('Cyphers::' + suite.upcase).new(seed, params)
			rescue
				raise CypherFailed
			end
			@seed = seed
		end

		def encrypt(input)
			worker = @cypher.make_worker_to_encrypt
			FilterIO.new input do |data, state|
				worker.process(data, state)
			end
		end

		def decrypt(input)
			worker = @cypher.make_worker_to_decrypt
			FilterIO.new input do |data, state|
				worker.process(data, state)
			end
		end	
	end
end

