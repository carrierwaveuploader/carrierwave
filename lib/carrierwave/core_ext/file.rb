class File
  def size
    File.size(path)
  end

  def empty?
    size == 0
  rescue Errno::ENOENT
    false
  end
end
