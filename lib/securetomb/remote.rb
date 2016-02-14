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

		def get_blob(id)
			@backend.get_blob(id)
		end

		def put_blob(input)
			@backend.put_blob(input)
		end

		def delete_blob(id)
			if @backend.respond.to? :delete_blob
				@backend.delete_blob(id)
			end
		end

		def get(name)
			@backend.get(name)
		end

		def put(name, input)
			@backend.put(name, input)
		end
		
		attr_reader :backend
	end

end
