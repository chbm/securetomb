require "./lib/securetomb"
require "./lib/securetomb/cyphers/aes"
require "test/unit"
require "stringio"
require "pp"

module Cyphers
	class AES
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

		aes = Cyphers::AES.new("\x00" * 32, [256])

		masterkey_check = OpenSSL::PKCS5::pbkdf2_hmac_sha1('teste', "\x00" * 32 , 200000, 32)
		basesig_check = "\x00aes256OF".b

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

	def test_aes_badlength
		[ [1], [], ['a'] ].each do |l|
			assert_raise SecureTomb::Cyphering::CypherFailed do 
				SecureTomb::Cyphering.new("\x00" * 32, 'aes', l)
			end
		end

		['256', '192'].each do |l|
			assert_nothing_raised do 
				SecureTomb::Cyphering.new("\x00" * 32, 'aes', [l])
			end
		end

	end

	def test_aes_crypt
		ENV["TOMBPASS"]= "teste"

		aes = SecureTomb::Cyphering.new("\x00" * 32, 'aes', [256])
		

		origfile = Tempfile.new('aestestin')
	  IO::write(origfile.path, "\x00123456789\xff" * 5357 )
		resultfile = Tempfile.new('aestestout')
		
		IO::copy_stream(aes.decrypt(aes.encrypt(origfile)), resultfile)

		assert(FileUtils.compare_file(origfile.path, resultfile.path) == true)
		origfile.close
		resultfile.close


		origfile = Tempfile.new('aestestin')
	  IO::write(origfile.path, "\x00" * 53571 )
		resultfile = Tempfile.new('aestestout')
		
		IO::copy_stream(aes.decrypt(aes.encrypt(origfile)), resultfile)

		assert(FileUtils.compare_file(origfile.path, resultfile.path) == true)
		origfile.close
		resultfile.close

	end

		
	def test_aes_stress
		aes = SecureTomb::Cyphering.new("\x00" * 32, 'aes', ['256'])
		randomstream = File.open('/dev/random')
		(1..100).each do 
			origfile = Tempfile.new('aestestin')
			resultfile = Tempfile.new('aestestout')
			IO::copy_stream(randomstream, origfile, Random::rand(1000000))
			origfile.rewind

			IO::copy_stream(aes.decrypt(aes.encrypt(origfile)), resultfile)

			assert(FileUtils.compare_file(origfile.path, resultfile.path) == true)
			origfile.close
			resultfile.close
		end
	end

end
