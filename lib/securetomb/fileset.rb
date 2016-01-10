require 'sqlite3'
require 'tempfile'
require 'socket'
require 'digest'
require 'securerandom'


module SecureTomb

	class FileSet
		def initialize(stream)
			@dbfile = Tempfile.new('fsset')
			File.copy_stream(stream, @dbfile)
			@sql = SQLite3::Database.new(@dbfile.path)
		end

		def self.fromScratch(name, path)
			dbfile = Tempfile.new('fsset')
			sql = SQLite3::Database.new(dbfile.path)
			sql.execute_batch <<-SQL
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
				create table meta (
					localpath text,
					localhost text
				);
			SQL
			sql.execute("insert into meta values (?,?)", path, Socket.gethostname)	
	
			FileSet.new(dbfile)
		end


		def outstream
			@dbfile #wll this work ? 
		end

		def __walkDir(path, filelist)
			Dir.entries(@localpath + path).each do |f|
				relp = path + f
				fullp = @localpath + relp
				if f != '.' && f != '..'
					if File.directory?(fullp)
						__walkDir(relp + '/', filelist)
					else
						row = @sql.execute("select mtime, perms, sha1 from files where path = ?",f)
						if row.empty? || 
							row[0][0] < File::Stat.new(fullp).mtime ||
							row[0][2] != Digest::SHA1.file(fullp).hexdigest then
							filelist.push(relp)
						end
					end
				end
			end
			filelist
		end
	
		def diff
			row = @sql.execute("select localpath from meta limit 1;")
			@localpath = row[0][0]
			filelist = []
			__walkDir('/', filelist)
		end

		def putDB(remote, cypher)
			remote.put('fileset', cypher.encrypt(@dbfile))
		end

		def sync(filelist, remote, cypher)
			filelist.each do |f|
				fullp = @localpath + f
				puts "Sync #{fullp}"
				digest = Digest::SHA1.file(fullp).hexdigest
				stat = File::Stat.new(fullp)
				fstream = cypher.encrypt(File.open(fullp))
				uuidlist = remote.putBlob(fstream)
				@sql.execute("insert or ignore into files (path) values (?)", f)
				@sql.execute("update files set sha1 = ?, mtime = ? where path = ?", digest, stat.mtime.to_s, f)
				row = @sql.execute("select id from files where path = ?", f)
				uuidlist.each_index do |i|
					@sql.execute("insert into blobs values (?,?,?)", row[0][0], uuidlist[i], i)
				end

				putDB(remote, cypher)
			end
		end

	end

end
