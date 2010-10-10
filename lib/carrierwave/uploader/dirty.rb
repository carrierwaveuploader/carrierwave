# # encoding: utf-8
#
# module CarrierWave
#   module Uploader
#     module Dirty
#       extend ActiveSupport::Concern
#
#       include CarrierWave::Uploader::Callbacks
#
#       attr_reader :identifier_was, :new_identifier
#
#       def stale_model?
#          self.store_dir_changed? || self.identifier_changed?
#       end
#
#       ##
#       # Override this method in your uploader to check if the store_dir or the filename has been updated.
#       #
#       # === Returns
#       #
#       # [NilClass, Boolean] true if the model has been changed, false otherwise
#       #
#       # === Examples
#       #
#       #     def store_dir_was
#       #       model.folder_was # because store_dir is based on the folder property of the model
#       #     end
#       #
#       def store_dir_was
#         self.store_dir
#       end
#
#       def store_dir_changed?
#         self.store_dir != self.store_dir_was
#       end
#
#       def store_path_was(for_file=identifier_was)
#         File.join([store_dir_was, full_filename(for_file)].compact)
#       end
#
#       def new_identifier
#         self.model.send(:_mounter, self.mounted_as).identifier
#       end
#
#       ##
#       # Override this method in your uploader to check if the identifier has been updated.
#       #
#       def identifier_was
#         self.new_identifier
#         # mounter = self.model.send(:_mounter, self.mounted_as)
#         # model.send(:"#{mounter.send(:serialization_column)}_was")
#       end
#
#       def identifier_changed?
#         new_identifier != identifier_was
#         # mounter = self.model.send(:_mounter, self.mounted_as)
#         # model.send(:"#{mounter.send(:serialization_column)}_changed?")
#       end
#
#     end # Dirty
#   end # Uploader
# end # CarrierWave
