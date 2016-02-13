require 'digest'
require 'openssl'
require 'filter_io'
require 'pp'

#require 'pry'


module Cyphers
	class AES
		class BadSignature < RuntimeError
		end

		class BadLength < RuntimeError
		end

		class Worker
			class NeedMoreData < RuntimeError
			end

			def initialize(engine, kl, encrypt, masterkey, randomness)
				@encrypting = encrypt
				@masterkey = masterkey # jebus, __check_sig needs it
				@engine = engine
				@e = engine.new(kl, :OFB)
				@keyiv = randomness.byteslice(16,16)
				@sig = "aes" + kl.to_s + 'OF'

				if @encrypting then
					@e.encrypt
					@iv = @e.random_iv
					@localkey = @e.random_key
					keyengine = engine.new(kl,:OFB)
					keyengine.iv= @keyiv
					keyengine.key= masterkey
					@cypheredkey =  keyengine.update(@localkey) + keyengine.final
				else
					@e.decrypt
					@initialized = false
				end
			end

			def process(data, state)

				#binding.pry
				
				if @encrypting then
					if state.bof? then
						# inject version = 0, "aes256\0\0", cypheredkey, iv, hmac_sha1(iv, localkey)
					  h = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha1'),@localkey , @iv)
						return "\x00".b + @sig + @cypheredkey + @iv + h + @e.update(data)
					elsif state.eof? then
						return @e.update(data) + @e.final
					else 
						return @e.update(data)
					end
				else #decrypt
					if (not @initialized) then
						begin
							buf = __check_signature_and_init(data)
						rescue Worker::NeedMoreData
							return ['', data]
						end
						return @e.update(buf)
					elsif state.eof? then
						return @e.update(data) + @e.final
					else
						return @e.update(data)
					end
				end
			end

			def __check_signature_and_init(data)
				# version 1b offset 0			= 0
				# cypher sig 8b offset 1	= "aes256" 
				# cyphered key 32b offset 9
				# IV 16b offset 41
				# IV HMAC 40b offset 57
				#
				#           1           4  
				# 01234567890 ....      01
				# 0aes25600cyphered....key

				if data.size < 97 then
					raise NeedMoreData
				end

				if data.byteslice(0,9) != "\x00"+@sig
					raise Cyphers::AES::BadSignature
				end
				temp = @engine.new(256, :OFB)
				temp.decrypt
				temp.iv= @keyiv
				temp.key= @masterkey
				@localkey = temp.update(data.byteslice(9,32)) + temp.final
				@iv = data.byteslice(41,16)
				h = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha1'), @localkey, @iv)
				if h != data.byteslice(57,40) then
					raise Cyphers::AES::BadSignature
				end
				@e.key= @localkey
				@e.iv= @iv
				@initialized = true

				data[97..-1]
			end

		end


		def initialize(seed, *params)
			@keylength = (params[0].length && params[0][0].to_i) || 256
			raise Cyphers::AES::BadLength unless @keylength == 256 || @keylength == 192 # nuting else
							
			@engine = OpenSSL::Cipher::AES
			@randomness = seed
			if ENV.key? "TOMBPASS"
				passphrase = ENV["TOMBPASS"]
			else
				puts "input your passphrase: "
				passphrase = STDIN.gets.chomp
			end
			@masterkey = OpenSSL::PKCS5.pbkdf2_hmac_sha1(passphrase, seed, 200000, 32)
		end

		def make_worker_to_encrypt
			Worker.new(@engine, @keylength, true, @masterkey, @randomness)
		end

		def make_worker_to_decrypt
			Worker.new(@engine, @keylength, false, @masterkey, @randomness)
		end

	end
end

