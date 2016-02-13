require 'json'
require 'stringio'
require 'base64'

require './lib/securetomb/fileset'
require './lib/securetomb/remote'
require './lib/securetomb/cyphering'


module SecureTomb

	class Make
		def initialize(remoteurl)
			@remote = Remote.new(remoteurl)
			if not @remote then
				puts "don't have a driver for that remote sorry"
				return nil
			end
		end

		def init(name, path, cypher_name, *cypher_params)
			randomseed = Cyphering.randombytes


			@cypher = Cyphering.new(randomseed, cypher_name, *cypher_params) 

			@remote.put('meta', StringIO.new(JSON.generate({
				:version => 0,
				:name => name,
				:cyphername => cypher_name,
				:cypherparams => cypher_params,
				:randomseed => Base64.encode64(randomseed)
			})))

			@fileset = FileSet.fromScratch(name, path, @remote, @cypher)
			@fileset.putDB(@remote, @cypher)

			puts "Initialized #{name}"
		end

		def syncup()	
			begin	
				metafile = @remote.get('meta')
			rescue Errno::ENOENT
				raise NoTomb
			end
			meta = JSON.load(metafile)

			@cypher = Cyphering.new(Base64.decode64(meta["randomseed"]), meta["cyphername"], meta["cypherparams"])

			@fileset = FileSet.new(@remote, @cypher)
			@fileset.sync(@remote, @cypher)
		end

		def syncdown(remoteurl)

		end
	end

end
