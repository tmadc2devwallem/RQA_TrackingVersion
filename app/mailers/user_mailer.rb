# Helper class for:
# - Send email
# - Receive and extract attachments (IMAP and POP3)
#

class UserMailer < ActionMailer::Base
  default from: 'error-from@rubyonrails.com'
  require 'net/imap' # for tracking email
  require 'fileutils'


  # Author: dathi
  # Send an email with custom SMTP header.
  # Params:
  #   mail_from: sender
  #   mail_to: receiver
  #   mail_subject: subject of mail
  #   mail_attachment: attached file
  #   type: 'GRA' or 'REQ' or nil
  #   mail_body: content of mail
  def send_mail(mail_from, mail_to, mail_subject, mail_attachment = nil, type = nil, mail_body = nil)
    begin
      attached_file = ''
      if !mail_attachment.nil?
        LoggerHelper.log_debug('rqa.log', 'Absolute path to attachment: ' + mail_attachment, __FILE__, __LINE__)

        ext = ApplicationHelper.get_rqa_config('attachment_extension')
        LoggerHelper.log_debug('rqa.log', 'Attachment extension in config: ' + ext, __FILE__, __LINE__)

        attached_file = File.basename(mail_attachment).gsub('.zip', '.' + ext)
        LoggerHelper.log_debug('rqa.log', 'Attachment file: ' + attached_file, __FILE__, __LINE__)

        attachments.inline[attached_file] = File.read(mail_attachment, mode: 'rb')
        LoggerHelper.log_info('rqa.log', 'Read attachment: done.', __FILE__, __LINE__)
      end
      if !type.nil?
        header = '{"COMPANY": "WALLEM", "APPLICATION": "TPS RQA", "TYPE": "'
        header += type.to_s.upcase
        header += '", "VERSION": "<TBD>", "COMMENT": "<TBD>"}'
        LoggerHelper.log_debug('rqa.log', 'HEADER: ' + header, __FILE__, __LINE__)

        headers['X-CUSTOM'] = header
        LoggerHelper.log_info('rqa.log', 'Write custom header: done.', __FILE__, __LINE__)
      end

      LoggerHelper.log_debug('rqa.log', 'Sent mail. FROM: ' + mail_from, __FILE__, __LINE__)
      LoggerHelper.log_debug('rqa.log', 'Sent mail. TO: ' + mail_to, __FILE__, __LINE__)
      LoggerHelper.log_debug('rqa.log', 'Sent mail. SUBJECT: ' + mail_subject, __FILE__, __LINE__)
      LoggerHelper.log_debug('rqa.log', 'Sent mail. ATTACHMENT: ' + attached_file, __FILE__, __LINE__)

      if mail_body.nil?
        LoggerHelper.log_info('rqa.log', 'Body is null => using body template.', __FILE__, __LINE__)
        mail(from: mail_from, to: mail_to, subject: mail_subject).deliver!
      else
        mail(from: mail_from, to: mail_to, subject: mail_subject, body: mail_body).deliver!
      end
      LoggerHelper.log_info('rqa.log', 'Sent mail: done and successfully.', __FILE__, __LINE__)
    rescue => ex
      LoggerHelper.log_error('rqa.log', ex.message, __FILE__, __LINE__)
      LoggerHelper.log_error('rqa.log', ex.backtrace.join("\n").to_s, __FILE__, __LINE__)
      return false
    end
    return true
  end

  # TPSBF-363, hthngoc
  # IMAP
  # Get last checked id or generate new file
  def self.get_last_uid (fname)
    uid = 0
    imap = Net::IMAP.new(ApplicationHelper.get_config_key_from_xml('imap_server'),
                         ApplicationHelper.get_config_key_from_xml('imap_port'))
    imap.login(ApplicationHelper.get_config_key_from_xml('username'),
               TrackingMail.decode_pwd(ApplicationHelper.get_config_key_from_xml('password')))
    imap.select(ApplicationHelper.get_config_key_from_xml('imap_mail_folder'))
    msgs = imap.search([ApplicationHelper.get_config_key_from_xml('imap_search_by'),
                        ApplicationHelper.get_config_key_from_xml('imap_search_value')]).reverse
    msgs.each do |msgID|
      msg = imap.fetch(msgID, ['ENVELOPE', 'UID', 'BODY'])[0]
      uid = msg.attr['UID']
      break
    end
    imap.close
    imap.disconnect

    if uid > ApplicationHelper.get_config_key_from_xml('imap_expand_id').to_i
      last_uid = uid - ApplicationHelper.get_config_key_from_xml('imap_expand_id').to_i
    else
      last_uid = uid
    end

    if File.file?(fname)
      last_uid = File.read(fname)
      if last_uid.blank?
        last_uid = uid
      end
      last_uid = last_uid.to_i
    else
      file = File.open(fname, 'w')
      file.puts last_uid
      file.close
    end
    last_uid
  end

  # TPSBF-363, hthngoc
  # IMAP
  # Update last checked id
  def self.update_uid(uid, fname)
    last_uid = uid
    if $last_uid
      if $last_uid.is_a?(Integer)
        last_uid = $last_uid
      end

      file = File.open(fname, 'w')
      file.puts last_uid
      file.close
    end
  end

  # TPSBF-363, hthngoc
  # POP3
  # Get last checked time or generate new file
  def self.get_last_time (fname)
    time_now = Time.now.utc
    if File.file?(fname)
      $last_sent = File.read(fname)
      if $last_sent.blank?
        $last_sent = time_now
        # update last_sent to file
        file = File.open(fname, 'w')
        file.puts $last_sent.to_s
        file.close
      else
      end
    else
      $last_sent = time_now
      # update last_sent to file
      file = File.open(fname, 'w')
      file.puts $last_sent.to_s
      file.close
    end
    $last_sent.to_s.to_time
  end

  # TPSBF-363, hthngoc
  # POP3
  # Update last checked time
  def self.update_time(on_time, fname)
    last_sent = on_time
    if $last_checked_on
      last_sent= $last_checked_on
    end

    file = File.open(fname, 'w')
    file.puts last_sent.to_s
    file.close
  end

  # Dec31 - hthngoc
  # Validate mail credentials
  def self.account_valid?(mail_server, mail_server_port, via_imap, mail_id, mail_pwd)
    begin
      if via_imap == 'true'
        imap = Net::IMAP.new(mail_server, mail_server_port)
        imap.login(mail_id, mail_pwd)
        imap.select('Inbox')
        true
      else
        Mail.defaults do
          retriever_method(:pop3,
                           :address => mail_server,
                           :port => mail_server_port,
                           :user_name => mail_id,
                           :password => mail_pwd)
        end
        first_mail = Mail.first
        true
      end
    rescue => e
      puts e
      false
    end
  end

  # TPSBF-363, hthngoc
  # Track mail via IMAP
  def self.track_email(mail_server, mail_server_port = 143, mail_id, mail_pwd,
      mail_folder, search_type, search_query, subject, last_saved_id, delete_after_read, download_folder)
    begin
      imap = Net::IMAP.new(mail_server, mail_server_port)
      imap.login(mail_id, TrackingMail.decode_pwd(mail_pwd))
      imap.select(mail_folder)
      msgs = imap.search([search_type, search_query]).reverse
      is_first_check = true

      msgs.each do |msgID|
        msg = imap.fetch(msgID, ['ENVELOPE', 'UID', 'BODY'])[0]
        uid = msg.attr['UID']
        puts "Mail: #{msg.attr['ENVELOPE'].subject} - #{uid}"
        if uid > last_saved_id
          if is_first_check
            $last_uid = uid
            is_first_check = false
          end
          if msg.attr['ENVELOPE'].subject.to_s.downcase.include? subject.downcase
            body = msg.attr['BODY']
            if body
              i = 1
              if body.is_a? Net::IMAP::BodyTypeMultipart
                if body.parts
                  while body.parts[i] != nil
                    # additional attachments attributes
                    file_type = body.parts[i].media_type
                    file_name = body.parts[i].param['NAME']
                    unless file_name
                      file_name = body.parts[i].param['FILENAME']
                    end
                    encoding= body.parts[i].encoding
                    i += 1
                    attachment = imap.fetch(msgID, "BODY[#{i}]")[0].attr["BODY[#{i}]"]
                    unless file_name.nil?
                      if encoding == 'BASE64' || file_type == 'TEXT'
                        dir = "#{download_folder}/#{Date.today.to_s}"
                        FileUtils.mkdir_p(dir) unless File.directory?(dir)
                        File.new("#{dir}/#{file_name}", 'wb').write(Base64.decode64(attachment))
                        puts "Saved file #{file_name} - email: #{msg.attr['ENVELOPE'].subject}"
                      else
                        puts 'Unknown encoding, can\'t write data to disk'
                      end
                    end
                  end
                end
              end
              if delete_after_read.downcase == 'true'
                puts 'Delete after checked'
                # mark as deleted after read
                imap.select(mail_folder)
                imap.uid_store(uid, '+FLAGS', [:Deleted])
              end
            end
            #imap.expunge
          end
        else
          puts "Touch last checked mail with id #{$last_uid}. Complete"
          break
        end
        GC.start
      end
      imap.close
      imap.disconnect
    rescue => e
      puts "Exception Tracking mail: #{e}"
    end
  end

  # Milestone of the last checking maildrop
  @mile_stone = false

  # TPSBF-363, hthngoc
  #
  # Usage:
  # Get last_sent from storage (DateTime)
  #  last_sent = '2013-12-21'.to_time
  #
  #  UserMailer.track_email_pop('pop.tma.com.vn', 110, 'hthngoc', 'passw0rd',
  #    'from', 'hthngoc@tma.com.vn', 'filtered string on subject', 50, 8, '2013-212-24 03:12:12', 'downloads')
  #
  # Update last_sent record after running this method.
  #  last_sent = $last_checked_on
  #
  def self.track_email_pop(mail_server, mail_server_port, mail_id, mail_pwd,
      sent_from, subject, mail_quantity, expand_time, last_sent_on, download_folder, get_zip_only = true,
      is_ssl = nil)
    begin
      if is_ssl
        Net::POP3.enable_ssl(OpenSSL::SSL::VERIFY_NONE)
      end

      Mail.defaults do
        retriever_method(:pop3,
                         :address => mail_server,
                         :port => mail_server_port,
                         :user_name => mail_id,
                         :password => TrackingMail.decode_pwd(mail_pwd))
      end
      is_first_check = true
      sent_on = Time.now.utc
      all_mails = Mail.find(:what => :last, :count => mail_quantity, :order => :desc)
      all_mails.each do |mail|
        puts "Checking email: #{mail.subject}"
        mail.header.fields.each do |field|
          begin
            sent_on = field.value.to_time
            puts "Sent on: #{sent_on}"
            break
          rescue
          end
        end
        diff = (sent_on - last_sent_on).to_i
        if is_first_check
          $last_checked_on = sent_on
          is_first_check = false
        end
        if diff == 0 || diff < 0
          if diff == 0
            puts 'Touch the last checked mail, escape remain maildrop'
            @mile_stone = true
            break
          else
            temp = sent_on + expand_time.hours
            if (temp - last_sent_on) < 0
              @mile_stone = true
              break
            end
          end
        else
          if mail.subject.to_s.downcase.include? subject.downcase
            mail.from.each do |from_mail|
              if from_mail.include? sent_from
                if mail.attachments
                  if mail.attachments.size
                    if mail.attachments.size > 0
                      puts "Number of attachments: #{mail.attachments.size}"
                      mail.attachments.each do |file|
                        if file.header.fields[0]
                          filter = false
                          if get_zip_only
                            # Get zip file only
                            filter = file.header.fields[0].field.sub_type.include? 'zip'
                          else
                            # Get all kinds of attachment with base64 encode
                            filter = file.header.fields[1].field.value.include? 'base64'
                          end
                          if filter
                            puts 'Begin writing attachment'
                            i = 0
                            while i < file.header.fields.count
                              begin
                                if file.header.fields[i].field
                                  fn = file.header.fields[i].field.filename.nil? ? file.header.fields[i].field.name :
                                      file.header.fields[i].field.filename
                                  is_fn = /\w+\.\w+/.match(fn).nil? ? nil : true
                                  if is_fn == true
                                    break
                                  end
                                end
                              rescue
                              end
                              i += 1
                            end
                          end
                          puts fn
                          if fn
                            dir = "#{download_folder}/#{Date.today.to_s}"
                            FileUtils.mkdir_p(dir) unless File.directory?(dir)
                            File.new("#{dir}/#{fn}", 'wb').write(Base64.decode64(file.body.raw_source))
                            puts 'End'
                            # $checked_id = mail.message_id
                          else
                            puts 'cant get filename'
                          end

                        else
                          puts 'File is not ZIP format or encoding Base64'
                        end
                      end
                    end
                  end
                end
              end
              # no need to check next "from".
              break
            end
          end
          @mile_stone = false
        end
        puts 'Checking next mail'
        GC.start
      end

      # check if we've already touch the previous checked email or not before leaving.
      if @mile_stone
        puts "Tracking finished, last checked email: #{$last_checked_on}"
        return sent_on
      else
        mail_quantity += mail_quantity
        puts "Re-track email#{mail_quantity}"
        track_email_pop(mail_server, mail_server_port, mail_id, mail_pwd,
                        sent_from, subject, mail_quantity, expand_time, last_sent_on, download_folder, get_zip_only)
      end
    rescue => e
      puts "Exception track mail POP3 #{e}"
    end
  end

  def self.track_email_auto
    if ApplicationHelper.get_config_key_from_xml('is_imap') == '0'
      puts 'POP3'
      last_sent = UserMailer.get_last_time(ApplicationHelper.get_config_key_from_xml('pop_fname'))
      is_get_zip_only = ApplicationHelper.get_config_key_from_xml('pop_get_zip_only').downcase == 'true' ? true : false
      is_ssl = ApplicationHelper.get_config_key_from_xml('pop_is_ssl').downcase == 'true' ? true : false

      UserMailer.track_email_pop(ApplicationHelper.get_config_key_from_xml('pop_server'),
                                 ApplicationHelper.get_config_key_from_xml('pop_port').to_i,
                                 ApplicationHelper.get_config_key_from_xml('username'),
                                 ApplicationHelper.get_config_key_from_xml('password'),
                                 ApplicationHelper.get_config_key_from_xml('pop_sent_from'),
                                 ApplicationHelper.get_config_key_from_xml('subject'),
                                 ApplicationHelper.get_config_key_from_xml('pop_number_of_mails').to_i,
                                 ApplicationHelper.get_config_key_from_xml('pop_expand_time').to_i,
                                 last_sent,
                                 ApplicationHelper.get_config_key_from_xml('download_folder'),
                                 is_get_zip_only, is_ssl)
      UserMailer.update_time(last_sent, ApplicationHelper.get_config_key_from_xml('pop_fname'))
    else
      puts 'IMAP'
      last_uid = UserMailer.get_last_uid(ApplicationHelper.get_config_key_from_xml('imap_fname'))
      UserMailer.track_email(ApplicationHelper.get_config_key_from_xml('imap_server'),
                             ApplicationHelper.get_config_key_from_xml('imap_port').to_i,
                             ApplicationHelper.get_config_key_from_xml('username'),
                             ApplicationHelper.get_config_key_from_xml('password'),
                             ApplicationHelper.get_config_key_from_xml('imap_mail_folder'),
                             ApplicationHelper.get_config_key_from_xml('imap_search_by'),
                             ApplicationHelper.get_config_key_from_xml('imap_search_value'),
                             ApplicationHelper.get_config_key_from_xml('subject'),
                             last_uid,
                             ApplicationHelper.get_config_key_from_xml('imap_delete_after_read'),
                             ApplicationHelper.get_config_key_from_xml('download_folder'))
      puts "Update UID #{$last_uid}"
      UserMailer.update_uid(last_uid, ApplicationHelper.get_config_key_from_xml('imap_fname'))
    end
  end

end
