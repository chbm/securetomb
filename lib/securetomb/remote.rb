require 'uri'

module SecureTomb

	class Remote
		class BadURL < RuntimeError
		end

		class UnknownScheme < RuntimeError
		end

		class RemoteFailed < RuntimeError
		end

		def initialize(url)
			@uri = URI(url)
			if not @uri.scheme then
				raise BadURL
			end
			
			begin
				require './lib/securetomb/remotes/' + @uri.scheme
			rescue LoadError
				raise UnknownScheme
			end

			begin
				@backend =  Object.const_get('Remotes::' + @uri.scheme.upcase).new(@uri)
			rescue
				raise RemoteFailed
			end
		end

		def method_missing(m, *args)
			@backend.send(m, *args)
		end

		attr_reader :backend
	end

end
