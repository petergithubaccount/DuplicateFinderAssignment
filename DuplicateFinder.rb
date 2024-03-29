require 'digest/md5'
require 'set'

#function for byte by byte comparison of two files
def byteCompare(f1, f2)
    byteChunk = 1
    file1 = File.open(f1,"rb")
    file2 = File.open(f2,"rb")
    until file1.eof?
        buffer1 = file1.read(byteChunk).bytes
        buffer2 = file2.read(byteChunk).bytes
        if buffer1!=buffer2
            file1.close
            file2.close
            return false
        end
        #puts buffer1.join(",")
        #puts buffer2.join(",")
    end
    file1.close
    if !file2.eof?
        file2.close
        return false
    end
    file2.close
    return true
end

#get root directory and file mask
puts "Input the root directory for duplicate searching"
root = gets.chomp
while !Dir.exists?(root) do
    puts "Directory #{root} doesn't exist"
    puts "Input the root directory for duplicate searching"
    root = gets.chomp
end
puts "Input the file mask"
mask = gets.chomp

#change root directory based on input and set file mask for search
#save each file to a hash entry, unless the files have the same key but are not identical bytewise
#if they are identical add it to the array of the hash entry
#key = md5 hash, value = array of files
#save md5 hash of duplicate files for lookup in hash into a set
Dir.chdir(root)
puts ""
puts "Searching directory #{Dir.pwd} and its subdirectories for duplicate files with mask #{mask}"
puts ""
filesToSearch = File.join("**",mask)
entries = Dir.glob(filesToSearch).select{|f| File.file? f}

entryHash = Hash.new {|h,k| h[k] = []}
duplicates = Set.new
for entry in entries
    md5 = Digest::MD5.hexdigest(File.open(entry){|f| f.read})
    #if key doesn't exist add it to hash
    #if hash exists compare the new file with file in hash byte by byte and if they are the same add it to the array
    #else - in case of MD5 collision, assumes only two collisions for a specific md5 hash, since I couldn't find a working example of a three way collision
    #else search hash entries with appended #0
    if !entryHash.key?(md5)
        entryHash[md5] << entry
    elsif byteCompare(entryHash[md5][0], entry)
        entryHash[md5] << entry
        duplicates.add(md5)

    #in case of hash collision
    else
        diffByteComp = entryHash.keys.select{|k| k.include? md5}
        for diffKey in diffByteComp
            #search wether a collision entry is already saved
            if byteCompare(entryHash[diffKey][0], entry)
                entryHash[diffKey] << entry
                duplicates.add(diffKey)
            else
                diffByteCompWithHash = diffByteComp.select {|x| x.include? "#"}
                #create a new two way collision entry
                if(diffByteCompWithHash.size()==0)
                    md5 = md5.concat("#").concat(0.to_s)
                    entryHash[md5] << entry
                #create a new three way and higher collision entry
                else
                    #maxOccStr = diffByteComp.select {|x| x[/([#][\d]+$)/]}
                    #maxAftHashDigit = findMax(maxOccStr)
                    #md5 = md5.concat("#").concat((maxOcc.to_i+1).to_s)
                    #entryHash[md5] << entry
                end
            end
        end
    end
end
if duplicates.size()>0
    #list duplicate files and their md5 hash from entryHash based on entries in set
    puts "List of duplicates"
    puts ""
    for duplicate in duplicates
        if duplicate.include? "#0"
            puts "MD5 Hash: ".concat(duplicate[0, duplicate.length-2]).concat(" - MD5 Collision with another file on specified path")
        else 
            puts "MD5 Hash: ".concat(duplicate)
        end
        puts "Duplicate files for Hash: "+ entryHash[duplicate].join(", ")
        puts ""
    end
else
    puts "No duplicates found"
end
