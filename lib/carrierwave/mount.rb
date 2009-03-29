module CarrierWave

  ##
  # If a Class is extended with this module, it gains the mount_uploader
  # method, which is used for mapping attributes to uploaders and allowing
  # easy assignment.
  #
  # You can use mount_uploader with pretty much any class, however it is
  # intended to be used with some kind of persistent storage, like an ORM.
  # If you want to persist the uploaded files in a particular Class, it
  # needs to implement a `read_uploader` and a `write_uploader` method.
  #
  module Mount

    ##
    # === Returns
    #
    # [Hash{Symbol => CarrierWave}] what uploaders are mounted on which columns
    #
    def uploaders
      @uploaders ||= {}
    end

    ##
    # === Returns
    #
    # [Hash{Symbol => Hash}] options for mounted uploaders
    #
    def uploader_options
      @uploader_options ||= {}
    end

    ##
    # Mounts the given uploader on the given column. This means that assigning
    # and reading from the column will upload and retrieve files. Supposing
    # that a User class has an uploader mounted on image, you can assign and
    # retrieve files like this:
    #
    #     @user.image # => <Uploader>
    #     @user.image = some_file_object
    #
    #     @user.store_image!
    #
    #     @user.image.url # => '/some_url.png'
    #
    # It is also possible (but not recommended) to ommit the uploader, which
    # will create an anonymous uploader class. Passing a block to this method
    # makes it possible to customize it. This can be convenient for brevity,
    # but if there is any significatnt logic in the uploader, you should do
    # the right thing and have it in its own file.
    #
    # === Added instance methods
    #
    # Supposing a class has used +mount_uploader+ to mount an uploader on a column
    # named +image+, in that case the following methods will be added to the class:
    #
    # [image]                   Returns an instance of the uploader only if anything has been uploaded
    # [image=]                  Caches the given file
    # [image_cache]             Returns a string that identifies the cache location of the file 
    # [image_cache=]            Retrieves the file from the cache based on the given cache name
    # [image_uploader]          Returns an instance of the uploader
    # [image_uploader=]         Sets the uploader (be careful!)
    # [store_image!]            Stores a file that has been assigned with +image=+
    # [image_integrity_error?]  Returns true if the last file to be assigned caused an integrty error
    #
    # === Parameters
    #
    # [column (Symbol)] the attribute to mount this uploader on
    # [uploader (CarrierWave::Uploader)] the uploader class to mount
    # [options (Hash{Symbol => Object})] a set of options
    # [&block (Proc)] customize anonymous uploaders
    #
    # === Options
    # 
    # [:ignore_integrity_errors (Boolean)] if set to true, integrity errors will result in caching failing silently
    #
    # === Examples
    #
    # Mounting uploaders on different columns.
    #
    #     class Song
    #       mount_uploader :lyrics, LyricsUploader
    #       mount_uploader :alternative_lyrics, LyricsUploader
    #       mount_uploader :file, SongUploader
    #     end
    #
    # This will add an anonymous uploader with only the default settings:
    #
    #     class Data
    #       mount_uploader :csv
    #     end
    #
    # this will add an anonymous uploader overriding the store_dir:
    #
    #     class Product
    #       mount_uploader :blueprint do
    #         def store_dir
    #           'blueprints'
    #         end
    #       end
    #     end
    #
    def mount_uploader(column, uploader=nil, options={}, &block)
      unless uploader
        uploader = Class.new do
          include CarrierWave::Uploader
        end
        uploader.class_eval(&block)
      end

      uploaders[column.to_sym] = uploader
      uploader_options[column.to_sym] = CarrierWave.config[:mount].merge(options)

      include CarrierWave::Mount::Extension

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}_uploader                            # def image_uploader
          _uploader_get(:#{column})                       #   _uploader_get(:image)
        end                                               # end
                                                          #
        def #{column}_uploader=(uploader)                 # def image_uploader=(uploader)
          _uploader_set(:#{column}, uploader)             #   _uploader_set(:image, uploader)
        end                                               # end
                                                          #
        def #{column}                                     # def image
          _uploader_get_column(:#{column})                #   _uploader_get_column(:image)
        end                                               # end
                                                          #
        def #{column}=(new_file)                          # def image=(new_file)
          _uploader_set_column(:#{column}, new_file)      #   _uploader_set_column(:image, new_file)
        end                                               # end
                                                          #
        def #{column}_cache                               # def image_cache
          _uploader_get_cache(:#{column})                 #   _uploader_get_cache(:image)
        end                                               # end
                                                          #
        def #{column}_cache=(cache_name)                  # def image_cache=(cache_name)
          _uploader_set_cache(:#{column}, cache_name)     #   _uploader_set_cache(:image, cache_name)
        end                                               # end
                                                          #
        def store_#{column}!                              # def store_image!
          _uploader_store!(:#{column})                    #   _uploader_store!(:image)
        end                                               # end
                                                          #
        def #{column}_integrity_error?                    # def image_integrity_error?
          _uploader_integrity_errors[:#{column}]          #   _uploader_integrity_errors[:image]
        end                                               # end
      RUBY
    end

    module Extension

      ##
      # overwrite this to read from a serialized attribute
      #
      def read_uploader(column); end

      ##
      # overwrite this to write to a serialized attribute
      #
      def write_uploader(column, identifier); end

    private

      def _uploader_get(column)
        @_uploaders ||= {}
        @_uploaders[column] ||= self.class.uploaders[column].new(self, column)
      end

      def _uploader_set(column, uploader)
        @_uploaders ||= {}
        @_uploaders[column] = uploader
      end

      def _uploader_options(column)
        self.class.uploader_options[column]
      end

      def _uploader_get_column(column)
        return _uploader_get(column) unless _uploader_get(column).blank?

        identifier = read_uploader(column)

        unless identifier.blank?
          _uploader_get(column).retrieve_from_store!(identifier)
          _uploader_get(column)
        end
      end

      def _uploader_set_column(column, new_file)
        _uploader_get(column).cache!(new_file)
        _uploader_integrity_errors[column] = nil
      rescue CarrierWave::IntegrityError => e
        _uploader_integrity_errors[column] = true
        raise e unless _uploader_options(column)[:ignore_integrity_errors]
      end

      def _uploader_get_cache(column)
        _uploader_get(column).cache_name
      end

      def _uploader_set_cache(column, cache_name)
        _uploader_get(column).retrieve_from_cache(cache_name) unless cache_name.blank?
      end

      def _uploader_store!(column)
        unless _uploader_get(column).blank?
          _uploader_get(column).store!
          write_uploader(column, _uploader_get(column).identifier)
        end
      end

      def _uploader_integrity_errors
        @_uploader_integrity_errors ||= {}
      end

    end # Extension

  end # Mount
end # CarrierWave
