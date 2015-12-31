require './lib/securetomb/fileset'
require './lib/securetomb/remote'

module SecureTomb

	def self.init(remoteurl, name, path)
		@remote = Remote.new(remoteurl)
		if not @remote then
			puts "don't have a driver for that remote sorry"
			return nil
		end
		@fileset = FileSet.new(name, path)
	end


end
