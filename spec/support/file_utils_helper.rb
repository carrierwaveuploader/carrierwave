module FileUtilsHelper
  # NOTE: Make FileUtils.mkdir_p to raise error only once
  def fake_failed_mkdir_p(error)
    original_mkdir_p = FileUtils.method(:mkdir_p)
    mkdir_p_called = false
    allow(FileUtils).to receive(:mkdir_p) do |args|
      if mkdir_p_called
        original_mkdir_p.call(*args)
      else
        mkdir_p_called = true
        raise error
      end
    end
  end
end
