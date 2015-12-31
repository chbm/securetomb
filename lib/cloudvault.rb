require 'sqlite3'
require 'tempfile'

module CloudVault



	class FileSet
		def initalize
			self.__startDB
		end
	
		def __startDB
			@dbfile = Tempfile.new()
			@sql = SQLite3::Database.new(@dbfile)
	end

end

