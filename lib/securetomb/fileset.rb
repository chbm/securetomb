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
				# TODO here we'd handle fileset versions
				@dbfile.sync= true
				File.copy_stream(cypher.decrypt(remote.get('fileset')), @dbfile)
				@dbfile.fsync
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
					sha1 char(40),
					viewed smallint
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

		def __walkDir(path, &block)
			Dir.entries(@localpath + path).each do |f|
				relp = path + f
				fullp = @localpath + relp
				isdir = File.directory?(fullp)
				if f != '.' && f != '..'
					if isdir 
						relp = relp + '/'
					end
					row = @sql.execute("select mtime, size, perms, sha1 from files where path = ?",relp)
					if isdir
						if row.empty?
							yield relp, true
						end
						__walkDir relp, &block
					else
						fstat = File::Stat.new(fullp)
						if row.empty? || 
							row[0][0] < fstat.mtime.to_i ||
							row[0][1] != fstat.size ||
							row[0][3] != Digest::SHA1.file(fullp).hexdigest then
							yield relp, false
						end
					end
					@sql.execute('update or ignore files set viewed = 1 where path = ?', relp)
				end
			end
		end
	
		def putDB(remote, cypher)
			o = self.outstream
			remote.put('fileset', cypher.encrypt(o))
			o.close
		end

		def sync(remote, cypher)
			row = @sql.execute('select localpath from meta limit 1;')
			@localpath = row[0][0]
			@sql.execute('update files set viewed = 0')
			__walkDir '/'  do |f, isdir|
				fullp = @localpath + f
				print "Sync #{fullp} "
				uuidlist = []
				stat = File::Stat.new(fullp)
				digest = ''
				if !isdir
					digest = Digest::SHA1.file(fullp).hexdigest
					if stat.size > 0 
						fstream = cypher.encrypt(File.open(fullp))
						uuidlist = remote.putBlob(fstream)
						fstream.close
						print "uploaded."
					else
						print "nothing to upload"
					end
				end
				
				@sql.transaction
				@sql.execute("insert or ignore into files (path) values (?)", f)
				@sql.execute("update files set sha1 = ?, mtime = ?, size = ?, viewed = 1  where path = ?", digest, stat.mtime.to_i, stat.size, f)
				row = @sql.execute("select id from files where path = ?", f)
				@sql.execute("delete from blobs where file = ?", row[0][0]) # no incremental updates of files
				uuidlist.each_index do |i|
					@sql.execute("insert into blobs values (?,?,?)", row[0][0], uuidlist[i], i)
				end
				@sql.commit

				putDB(remote, cypher)
				print "\n"
			end
		
			rows = @sql.execute('select path from files where viewed = 0')
			if rows.length > 0
				print "Forgeting " + rows.map{|x| x[0] }.join(' , ')
				@sql.execute('delete from files where viewed = 0')
				print "\n"
				# XXX TODO CLEANUP BLOBS!!
			end
			putDB(remote, cypher)
			puts "Done."
		
		end

	end

end
