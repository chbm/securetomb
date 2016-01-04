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

		@fileset = FileSet.new(name, path)
		
		@cypher = Cyphering.new(cypher_name, cypher_params) 

		@remote.put('meta', StringIO.new(JSON.generate({
			:version => 0,
			:name => name,
			:cyphername => cypher_name,
			:cypherparams => cypher_params
		})))

		@remote.put('fileset', @cypher.encrypt(@fileset.outstream))
	end

	def sync 
	end

end
