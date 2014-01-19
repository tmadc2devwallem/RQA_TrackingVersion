module ApplicationHelper

  require 'date'
  require 'fileutils'

  GIT_URI = 'http://137.116.158.228:11111/RQA.git'
  RQA_FOLDER = 'rqa'
  EXCEPTION_FILES = %w/.zip .rar .sqlite3/

  def self.get_config_key_from_xml(key)
    file = File.open(Rails.root.join('public/config/', 'RQA_Mail_Info.xml').to_s)
    root = Nokogiri::XML(file)
    key = root.xpath("//rqa_mail_info//#{key}")
    key_value = key.text
    file.close
    key_value
  end

  def self.get_rqa_config(key)
    file = File.open(Rails.root.join('public/config/', 'tracking_config.xml').to_s)
    root = Nokogiri::XML(file)
    node = root.xpath("//rqa_config//#{key}")
    value = node.text
    file.close
    value.strip
  end

  def self.copy_with_path(src, dst)
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
  end

end
