require "./lib/securetomb"
require "./lib/securetomb/cyphers/aes256"
require "test/unit"
require "stringio"
require "pp"

module Cyphers
	class AES256
		attr_reader :masterkey
		class Worker
			attr_reader :keyiv, :localkey, :cypheredkey
		end
	end
end

class TestAes < Test::Unit::TestCase
	class MockState
		def initialize
			@bof = true
			@eof = false
		end
		def bof?
			@bof
		end
		def eof?
			@eof
		end
		attr_accessor :bof, :eof
	end

	def test_aes_sig
		ENV["TOMBPASS"]= "teste"

		aes = Cyphers::AES256.new("\x00" * 32, '')

		masterkey_check = OpenSSL::PKCS5::pbkdf2_hmac_sha1('teste', "\x00" * 32 , 200000, 32)
		basesig_check = "\x00aes256\x00\x00".b

		assert(aes.masterkey == masterkey_check)

		encryptor = aes.make_worker_to_encrypt
		statestart = MockState.new
		stateend = MockState.new
		stateend.bof= false
		stateend.eof= true
		cyphertext = encryptor.process("\x00", statestart) + encryptor.process("\x00", stateend)

		assert(cyphertext.byteslice(0,9) == basesig_check)


		decryptor = aes.make_worker_to_decrypt
		part1 = decryptor.process(cyphertext.byteslice(0,98), statestart)
	  part2 = decryptor.process(cyphertext.byteslice(98,1024), stateend)
		assert(part1+part2 == "\x00\x00")	
	end
end
