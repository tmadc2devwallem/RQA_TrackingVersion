class TrackingMail
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion

  attr_accessor :username, :password, :subject, :download_folder, :rqa_pawd, :pop_server, :pop_port, :pop_sent_from,
                :pop_get_zip_only, :pop_number_of_mails, :pop_fname, :pop_expand_time,
                :is_imap, :imap_server, :imap_port, :imap_mail_folder, :imap_search_by, :imap_search_value,
                :imap_delete_after_read, :imap_fname,
                :bg_timeout, :clock_track_job, :clock_clear_log, :clock_clear_ram

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def self.read_file
    file = File.open(Rails.root.join('public/config/', 'RQA_Mail_Info.xml').to_s)
    root = Nokogiri::XML(file)
    @m = TrackingMail.new(
        username: root.xpath('//*//username').text,
        password: root.xpath('//*//password').text,
        subject: root.xpath('//*//subject').text,
        download_folder: root.xpath('//*//download_folder').text,
        rqa_pawd: root.xpath('//*//rqa_pawd').text,
        pop_server: root.xpath('//*//pop_server').text,
        pop_port: root.xpath('//*//pop_port').text,
        pop_sent_from: root.xpath('//*//pop_sent_from').text,
        pop_get_zip_only: root.xpath('//*//pop_get_zip_only').text,
        pop_number_of_mails: root.xpath('//*//pop_number_of_mails').text,
        pop_fname: root.xpath('//*//pop_fname').text,
        pop_expand_time: root.xpath('//*//pop_expand_time').text,
        is_imap: root.xpath('//*//is_imap').text,
        imap_server: root.xpath('//*//imap_server').text,
        imap_port: root.xpath('//*//imap_port').text,
        imap_mail_folder: root.xpath('//*//imap_mail_folder').text,
        imap_search_by: root.xpath('//*//imap_search_by').text,
        imap_search_value: root.xpath('//*//imap_search_value').text,
        imap_delete_after_read: root.xpath('//*//imap_delete_after_read').text,
        imap_fname: root.xpath('//*//imap_fname').text,
        bg_timeout: root.xpath('//*//bg_timeout').text,
        clock_track_job: root.xpath('//*//clock_track_job').text,
        clock_clear_log: root.xpath('//*//clock_clear_log').text,
        clock_clear_ram: root.xpath('//*//clock_clear_ram').text)
    file.close
    @m
  end

  def self.save_file(m)
    file = File.read(Rails.root.join('public/config/', 'RQA_Mail_Info.xml').to_s)
    xml = Nokogiri::XML(file)
    if m[:is_imap] == '1'
      xml.xpath('//*//imap_server')[0].content = m[:imap_server].delete(' ')
      xml.xpath('//*//imap_port')[0].content = m[:imap_port].delete(' ')
      xml.xpath('//*//imap_mail_folder')[0].content = m[:imap_mail_folder].squish()
      xml.xpath('//*//imap_search_by')[0].content = m[:imap_search_by].delete(' ')
      xml.xpath('//*//imap_search_value')[0].content = m[:imap_search_value].squish()
      xml.xpath('//*//imap_delete_after_read')[0].content = m[:imap_delete_after_read].delete(' ')
      xml.xpath('//*//imap_fname')[0].content = m[:imap_fname].delete(' ')
    else
      xml.xpath('//*//pop_server')[0].content = m[:pop_server].delete(' ')
      xml.xpath('//*//pop_port')[0].content = m[:pop_port].delete(' ')
      xml.xpath('//*//pop_sent_from')[0].content = m[:pop_sent_from].squish()
      xml.xpath('//*//pop_get_zip_only')[0].content = m[:pop_get_zip_only].delete(' ')
      xml.xpath('//*//pop_number_of_mails')[0].content = m[:pop_number_of_mails].delete(' ')
      xml.xpath('//*//pop_fname')[0].content = m[:pop_fname].squish()
      xml.xpath('//*//pop_expand_time')[0].content = m[:pop_expand_time].delete(' ')
    end
    xml.xpath('//*//username')[0].content = m[:username].delete(' ')
    xml.xpath('//*//password')[0].content = encode_pwd(m[:password])
    xml.xpath('//*//subject')[0].content = m[:subject].squish()
    xml.xpath('//*//download_folder')[0].content = m[:download_folder].squish()
    xml.xpath('//*//rqa_pawd')[0].content = m[:rqa_pawd].squish()
    xml.xpath('//*//is_imap')[0].content = m[:is_imap].delete(' ')
    # re-write XML file
    File.open(Rails.root.join('public/config/', 'RQA_Mail_Info.xml').to_s, 'w') do |f|
      f.write xml.to_xml
    end
  end

  # 31Dec - hthngoc
  # Encode before save password to xml file
  # Can enhance for more security
  def self.encode_pwd(raw_data)
    pwd = raw_data.delete(' ')
    pwd_64 = Base64.encode64(pwd)
    pwd_64 += 'R3T45632FZSL400'
    pwd_64
  end

  # 31Dec - hthngoc
  # Decode before send to Mail server
  # Can enhance for more security
  def self.decode_pwd(raw_data)
    pwd = raw_data[0..('R3T45632FZSL400'.length)]
    Base64.decode64(pwd)
  end

  def self.read_runtime
    file = File.open(Rails.root.join('public/config/', 'RQA_Mail_Info.xml').to_s)
    root = Nokogiri::XML(file)
    m = TrackingMail.new(
        bg_timeout: root.xpath('//*//bg_timeout').text,
        clock_track_job: root.xpath('//*//clock_track_job').text,
        clock_clear_log: root.xpath('//*//clock_clear_log').text,
        clock_clear_ram: root.xpath('//*//clock_clear_ram').text)
    file.close
    m
  end

  def self.save_runtime(m)
    file = File.read(Rails.root.join('public/config/', 'RQA_Mail_Info.xml').to_s)
    xml = Nokogiri::XML(file)
    xml.xpath('//*//bg_timeout')[0].content = m[:bg_timeout].to_i
    xml.xpath('//*//clock_track_job')[0].content = m[:clock_track_job].to_i
    xml.xpath('//*//clock_clear_log')[0].content = m[:clock_clear_log].to_i
    xml.xpath('//*//clock_clear_ram')[0].content = m[:clock_clear_ram].to_i
    # re-write XML file
    File.open(Rails.root.join('public/config/', 'RQA_Mail_Info.xml').to_s, 'w') do |f|
      f.write xml.to_xml
    end
  end

  def persisted?
    false
  end
end