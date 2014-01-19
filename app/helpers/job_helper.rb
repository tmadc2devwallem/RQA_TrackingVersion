module JobHelper
  require 'date'
  require 'fileutils'

  # Author: dathi
  # Get RQA version information from database. Then zip it and send to Shore.
  # Input: None.
  # Output: Zipped folder that contain RQA version and vessel code
  # Return:
  #   Absolute path of zip file => successfully
  #   Null => fail
  def self.get_version_and_send
    path_zipped_file = JobHelper.get_version

    LoggerHelper.log_debug('tracking_version.log',
                           'Path of zipped file is ' + path_zipped_file, __FILE__, __LINE__)
    if !path_zipped_file.nil?
      LoggerHelper.log_info('tracking_version.log',
                            '###### Send email with attachment.', __FILE__, __LINE__)
      UserMailer.send_mail('dathi@tma.com.vn',
                           'dathi@tma.com.vn',
                           '[Subject] RQA Version',
                           path_zipped_file)

      LoggerHelper.log_info('tracking_version.log',
                            '###### Delete zipped file after send mail.', __FILE__, __LINE__)
      File.delete(path_zipped_file)
    end
  end

  # Author: dathi
  # Get RQA version information from database. Then zip it.
  # Input: None.
  # Output: Zipped folder that contain RQA version and vessel code
  # Return:
  #   Absolute path of zip file => successfully
  #   Null => fail
  def self.get_version
    out_dir = Rails.root.join('public', 'outgoing').to_s + '/'
    temp_dir = out_dir + Time.now.to_i.to_s + '/'

    # create output directory
    if !Dir.exist?(temp_dir)
      FileUtils.mkpath(temp_dir)
    end

    begin
      version = ApplicationHelper.get_rqa_config('rqa_version')
      vessel_code = VesselInfo.first.strVslCode
      LoggerHelper.log_debug('tracking_version.log',
                             'vessel_code: ' + vessel_code, __FILE__, __LINE__)
      xml_path = XmlHelper.generate_version_info(vessel_code, version, temp_dir)
      LoggerHelper.log_debug('tracking_version.log',
                             'xml_path: ' + xml_path, __FILE__, __LINE__)
      if !xml_path.nil?
        # zip temp folder
        rqa_password = ApplicationHelper.get_rqa_config('rqa_password') + vessel_code
        LoggerHelper.log_debug('tracking_version.log',
                               'rqa_password: ' + rqa_password, __FILE__, __LINE__)

        zipped_file = out_dir + File.basename(xml_path).gsub('.xml', '.zip')
        LoggerHelper.log_debug('tracking_version.log',
                               'zipped_file: ' + zipped_file, __FILE__, __LINE__)

        # Zip all files in temp_dir (not include temp_dir) to zipped_file
        ZipHelper.zip(zipped_file, temp_dir + '.', rqa_password)
      end
    rescue => ex
      puts ex
      return nil
    end
    return zipped_file
  end

  # Author: dathi
  # Check version folder if exist => extract to source code.
  # Input: None.
  # Output: None.
  # Return: None.
  def self.update_code
    begin
      patch_path = Rails.root.join('public', 'patch').to_s + '/'
      if !Dir.exist?(patch_path)
        FileUtils.mkpath(patch_path)
      end

      last_sent = UserMailer.get_last_time('last_tracking_version.txt')
      tracking_mail('RQA Version', patch_path, last_sent)

      if !(Dir.entries(patch_path) - %w{ . .. }).empty?
        ext = ApplicationHelper.get_rqa_config('attachment_extension')
        Dir.glob(patch_path.join('*.' + ext)).each do |file|
          # change extension to .zip
          path_zipped_file = ZipHelper.change_to_zip(file)

          # get file name without extension, and parse to date
          array = File.basename(file, '.*').to_s.split('_')
          date = Time.at(array[1].to_i)

          # extract zipped file that was sent by Shore
          vessel_code = VesselInfo.first.strVslCode
          password = ApplicationHelper.get_rqa_config('rqa_password') + vessel_code
          ZipHelper.extract(path_zipped_file, Rails.root, password)

          # Update XML RQA config ===================> SHOULD BE ON SHORE
          xml_config = Rails.root.join('public/config/', 'RQA_config.xml').to_s
          XmlHelper.update_node_value(xml_config, 'rqa_version', '1.0.1')
        end
      end

    rescue => ex
      puts ex.message
      LoggerHelper.log_error('tracking_version.log', ex.message, __FILE__, __LINE__)
      LoggerHelper.log_error('tracking_version.log', ex.backtrace, __FILE__, __LINE__)
    end
  end

  def self.track_and_store_version
    out_dir = Rails.root.join('public', 'version').to_s + '/'
    if !Dir.exist?(out_dir)
      FileUtils.mkpath(out_dir)
    end
    last_sent = UserMailer.get_last_time('db/last_track_version_folder.txt')
    tracking_mail('Files', out_dir, last_sent)
  end

  def self.tracking_mail(subject, output_folder, last_sent)
    begin
      is_get_zip_only = ApplicationHelper.get_config_key_from_xml('pop_get_zip_only').downcase == 'false' ? false : true
      UserMailer.track_email_pop(ApplicationHelper.get_config_key_from_xml('pop_server'),
                                 ApplicationHelper.get_config_key_from_xml('pop_port').to_i,
                                 ApplicationHelper.get_config_key_from_xml('username'),
                                 ApplicationHelper.get_config_key_from_xml('password'),
                                 ApplicationHelper.get_config_key_from_xml('pop_sent_from'),
                                 subject,
                                 ApplicationHelper.get_config_key_from_xml('pop_number_of_mails').to_i,
                                 ApplicationHelper.get_config_key_from_xml('pop_expand_time').to_i,
                                 last_sent,
                                 output_folder,
                                 is_get_zip_only)
      UserMailer.update_time(last_sent, ApplicationHelper.get_config_key_from_xml('pop_fname'))
    rescue => ex
      puts ex.message
      LoggerHelper.log_error('tracking_version.log', ex.message, __FILE__, __LINE__)
      LoggerHelper.log_error('tracking_version.log', ex.backtrace.join("\n"), __FILE__, __LINE__)
    end
  end


  def self.get_latest_code_and_send
    # get ship revision via ship version
    ship_revision = 'a2bf6448fca2836a5b6fb9f5cfc675596e83abce'
    LoggerHelper.log_debug('tracking_version.log', "Current ship's revision is " + ship_revision)

    # get latest source code, then zip it as temp file
    LoggerHelper.log_info('tracking_version.log', '###### Get all changed files from ' + ship_revision + ' to HEAD')
    path_zipped_file = get_latest_source_code(ship_revision)
    LoggerHelper.log_debug('tracking_version.log', 'Path of zipped file is ' + path_zipped_file)

    # send the zip file via mail
    if !path_zipped_file.nil?
      LoggerHelper.log_info('tracking_version.log', '###### Send email with attachment.')
      UserMailer.send_mail('dathi@tma.com.vn',
                           'dathi@tma.com.vn',
                           '[Subject] Changed Files',
                           path_zipped_file)

      # delete zip file after sent successfully
      LoggerHelper.log_info('tracking_version.log', '###### Delete zipped file after send mail.')
      File.delete(path_zipped_file)
    end
  end

  def self.get_latest_source_code(ship_revision)
    out_dir = Rails.root.join('public', 'outgoing').to_s + '/'
    rqa_folder = out_dir + ApplicationHelper::RQA_FOLDER + '/'
    temp_dir = out_dir + Time.now.to_i.to_s + '/'

    # create output directory
    FileUtils.mkdir_p(temp_dir)

    # head version on GIT
    head = ''

    begin
      # Get all revision from 'ship_revision' to 'head_revision'
      diff_files = GitHelper.get_changed_files(ship_revision, rqa_folder)
      head = GitHelper.get_head(rqa_folder)

      # Loop and copy changed files to temp folder
      if !diff_files.nil?
        ext_config = ApplicationHelper.get_rqa_config('attachment_extension')
        files = diff_files[:files]
        files.each do |file|
          if File.exist?(rqa_folder + file[0])
            ext = File.extname(file[0])
            if ApplicationHelper::EXCEPTION_FILES.include?(ext) or ext.eql?(ext_config)
              next
            else
              ApplicationHelper.copy_with_path(rqa_folder + file[0], temp_dir + file[0])
            end
          end
        end
      end

      # zip temp folder
      zip_password = ApplicationHelper.get_rqa_config('password_zip')
      zipped_file = out_dir + head.sha.to_s + '.zip'
      ZipHelper.zip(zipped_file, temp_dir, zip_password)
    rescue => ex
      puts ex
      return nil
    end
    return zipped_file
  end

end
