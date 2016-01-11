require 'digest'

module Cyphers
	class AES256
		def initialize(*params)
			@engine = OpenSSL::Cipher::AES
			puts "input your passphrase: "
			@key = STDIN.gets.chomp
		end

		def start_encrypting
			@worker = @engine.new(256, :OFB)
			@worker.encrypt
			@worker.key= @key
			@worker.iv= Digest::SHA1.new.digest @key 
		end

		def start_decrypting
			@worker = @engine.new(256, :OFB)
			@worker.decrypt
			@worker.key= @key
			@worker.iv= Digest::SHA1.new.digest @key 
		end

		def process(data, state)
			if state.eof?
				@worker.update(data) + @worker.final
			else
				@worker.update(data)
			end
		end
	end
end

