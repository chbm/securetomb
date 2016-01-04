require 'sqlite3'
require 'tempfile'

module SecureTomb

	class FileSet
		def initialize(name, path)
			self.__startDB

		end

		def sync 

		end

		def outstream
			@dbfile #wll this work ? 
		end

		def __startDB
			# XXX this is where we fetch stuff
			@dbfile = Tempfile.new('fsset')
			puts @dbfile.path
			@sql = SQLite3::Database.new(@dbfile.path)

			@sql.execute_batch <<-SQL
				create table files (
					id integer primary key,
					path text,
					mtime datetime,
					perms smallint,
					sha1 char(40)
				);
				create index paths on files (path);
				create index mtimes on files (mtime);
				create index sig on files (sha1);
				create table blobs (
					file integer,
					blob text,
					ord integer,
					foreign key(file) references files(id)
				);
				create index bloborder on blobs (ord);
			SQL

		end

	end

end
