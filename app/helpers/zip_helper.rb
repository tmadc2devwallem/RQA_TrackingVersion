module ZipHelper

  require 'archive/zip'

  # Author: bmduc
  # Zip folder
  # Params:
  #   zipped_file: absolute path zipped file
  #   source_folder: absolute path source folder will be zipped.
  #   password: password to zip folder (optional)
  def self.zip(zipped_file, source_folder, password = nil)
    begin
      if File.exist?(zipped_file)
        File.delete(zipped_file)
      end
      if password.nil?
        Archive::Zip.archive(
            zipped_file,
            source_folder
        )
      else
        Archive::Zip.archive(
            zipped_file,
            source_folder,
            :encryption_codec => Archive::Zip::Codec::TraditionalEncryption,
            :password => password
        )
      end

      if File::directory?(source_folder)
        FileUtils.rm_rf(source_folder)
      else
        File.delete(source_folder)
      end
    rescue => ex
      puts ex
      return nil
    end
  end

  # Author: bmduc
  # Extract zipped file to destination
  # Params:
  #   zipped_file: source zipped file to extract
  #   destination: destination folder
  #   password: password to unzip file
  def self.extract(zipped_file, destination, password = nil)
    begin
      Archive::Zip.archive(zipped_file, destination)
      has_pass = false
    rescue => ex
      puts ex
      has_pass = true
    end
    begin
      if has_pass
        Archive::Zip.extract(zipped_file, destination, :password => password)
      end
    rescue => ex
      puts ex
      return false
    end
    return true
  end

  # change archived file to .zip file
  def self.change_to_zip(path_archived_file)
    begin
      path_file = File.expand_path('..', path_archived_file)
      ext = File.extname(path_archived_file)
      zip_file_name = File.basename(path_archived_file).gsub(ext, '.zip')
      path_zipped_file = path_file + '/' + zip_file_name
      File.rename(path_archived_file, path_zipped_file)
    rescue => ex
      puts ex
      puts ex.backtrace
      return nil
    end
    return path_zipped_file
  end

end
