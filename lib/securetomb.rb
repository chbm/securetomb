require 'json'
require 'stringio'

require './lib/securetomb/fileset'
require './lib/securetomb/remote'
require './lib/securetomb/cyphering'


module SecureTomb

	def self.init(remoteurl, name, path, cypher_name, cypher_params)
		@remote = Remote.new(remoteurl)
		if not @remote then
			puts "don't have a driver for that remote sorry"
			return nil
		end

		
		@cypher = Cyphering.new(cypher_name, cypher_params) 

		@remote.put('meta', StringIO.new(JSON.generate({
			:version => 0,
			:name => name,
			:cyphername => cypher_name,
			:cypherparams => cypher_params
		})))

		@fileset = FileSet.fromScratch(name, path, @remote, @cypher)
		@fileset.putDB(@remote, @cypher)

		puts "Initialized #{name}"
	end

	def self.sync(remoteurl)
		@remote = Remote.new(remoteurl)
		if not @remote then # groan
			puts "don't have a driver for that remote sorry"
			return nil
		end
	
		begin	
			metafile = @remote.get('meta')
		rescue Errno::ENOENT
			raise NoTomb
		end
		meta = JSON.load(metafile)

		@cypher = Cyphering.new(meta["cyphername"], meta["cypherparams"])

		@fileset = FileSet.new(@remote, @cypher)

		filetlist = @fileset.diff

		@fileset.sync(filetlist, @remote, @cypher)
	end

end
