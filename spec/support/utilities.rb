
def puts_on_file(file, string=nil)
  string ||= yield
  aFile = File.new(file, "w")
  aFile.write(string)
  aFile.close
end