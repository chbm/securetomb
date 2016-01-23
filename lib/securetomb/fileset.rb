require 'sqlite3'
require 'tempfile'
require 'socket'
require 'digest'
require 'securerandom'


module SecureTomb

	class FileSet
		def initialize(remote, cypher, stream=nil)
			@dbfile = Tempfile.new('fsset')
			if stream then
				File.copy_stream(stream, @dbfile)
			else
				File.copy_stream(cypher.decrypt(remote.get('fileset')), @dbfile)
			end
			@sql = SQLite3::Database.new(@dbfile.path)
		end

		def self.fromScratch(name, path, remote, cypher)
			dbfile = Tempfile.new('fsset')
			sql = SQLite3::Database.new(dbfile.path)
			sql.execute_batch <<-SQL
				create table files (
					id integer primary key,
					path text unique,
					size integer,
					mtime integer,
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
	
			FileSet.new(remote, cypher, dbfile)
		end


		def outstream
			File.open(@dbfile.path, "r") 
		end

		def __walkDir(path, filelist)
			Dir.entries(@localpath + path).each do |f|
				relp = path + f
				fullp = @localpath + relp
				if f != '.' && f != '..'
					if File.directory?(fullp)
						__walkDir(relp + '/', filelist)
					else
						row = @sql.execute("select mtime, size, perms, sha1 from files where path = ?",relp)
						fstat = File::Stat.new(fullp)
						if row.empty? || 
							row[0][0] < fstat.mtime.to_i ||
							row[0][1] != fstat.size ||
							row[0][3] != Digest::SHA1.file(fullp).hexdigest then
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
			o = self.outstream
			remote.put('fileset', cypher.encrypt(o))
			o.close
		end

		def sync(filelist, remote, cypher)
			filelist.each do |f|
				fullp = @localpath + f
				print "Sync #{fullp} "
				digest = Digest::SHA1.file(fullp).hexdigest
				stat = File::Stat.new(fullp)
				uuidlist = []
				if stat.size > 0 
					fstream = cypher.encrypt(File.open(fullp))
					uuidlist = remote.putBlob(fstream)
					fstream.close
					puts "uploaded."
				else
					puts "nothing to upload"
				end	
				@sql.execute("insert or ignore into files (path) values (?)", f)
				@sql.execute("update files set sha1 = ?, mtime = ?, size = ? where path = ?", digest, stat.mtime.to_i, stat.size, f)
				row = @sql.execute("select id from files where path = ?", f)
				uuidlist.each_index do |i|
					@sql.execute("insert into blobs values (?,?,?)", row[0][0], uuidlist[i], i)
				end

				putDB(remote, cypher)
			end
		end

	end

end
