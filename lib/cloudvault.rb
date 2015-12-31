require 'sqlite3'
require 'tempfile'

module CloudVault



	class FileSet
		def initalize
			self.__startDB
		end
	
		def __startDB
			# XXX this is where we fetch stuff
			@dbfile = Tempfile.new()
			puts @dbfile
			@sql = SQLite3::Database.new(@dbfile)

			@sql.execute_batch <<-SQL
				create table files (
					id integer primary key,
					path text,
					mtime datetime,
					perms smallint,
					sha1 char(40)
				);
				create index paths on file (path);
				create index mtimes on file (mtime);
				create index sig on file (sha1);
				create table blobs (
					file integer,
					blob text,
					order integer,
					foreign key (fileid) references table(id)
				);
				create index bloborder on blobs (order);
			SQL

		end

	end

end

