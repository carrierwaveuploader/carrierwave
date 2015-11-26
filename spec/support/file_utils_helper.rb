module FileUtilsHelper
  # NOTE: Make FileUtils.mkdir_p to raise `Errno::EMLINK` only once
  def fake_failed_mkdir_p
    original_mkdir_p = FileUtils.method(:mkdir_p)
    mkdir_p_called = false
    allow(FileUtils).to receive(:mkdir_p) do |args|
      if mkdir_p_called
        original_mkdir_p.call(*args)
      else
        mkdir_p_called = true
        raise Errno::EMLINK
      end
    end
  end
end
