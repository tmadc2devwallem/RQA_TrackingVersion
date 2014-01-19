module XmlHelper
  require 'fileutils'

  def self.generate_version_info(vessel_code, version, output_path = nil)
    begin
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Information {
          xml.Version version
          xml.VesselCode vessel_code
        }
      end
      xml_data = builder.to_xml

      # Save to file
      file_path = nil
      if !output_path.nil?
        file_path = File.join(output_path, vessel_code + '_' + version + '.xml')
      else
        file_path = File.join('public', 'outgoing', vessel_code + '_' + version + '.xml')
      end
      f = File.new(file_path, 'wb')
      f.write(xml_data)
      f.close
      return file_path
    rescue => ex
      puts ex
      LoggerHelper.log_error('tracking_version.log', ex.message, __FILE__, __LINE__)
    end
    return nil
  end

  def self.update_node_value(xml_path, node_name, new_value)
    begin
      # backup config file
      FileUtils.copy(xml_path, xml_path + '.bk')

      # read and parse the old file
      orig_f = File.open(xml_path, 'rb')
      xml = Nokogiri::XML(orig_f)
      xml.xpath('//' + node_name).each do |node|
        node.content = new_value
      end

      # create new file and write new content to it
      new_file = xml_path + '.new'
      new_f = File.new(new_file, 'wb')
      new_f.write(xml.to_xml)

      # close file
      new_f.close
      orig_f.close

      # delete olf file, and rename new file to orig name file
      FileUtils.remove(xml_path)
      FileUtils.move(new_file, xml_path)

    rescue => ex
      puts ex
      puts ex.backtrace
      LoggerHelper.log_error('tracking_version.log', ex.message, __FILE__, __LINE__)
    end
  end

  def self.update_node_attribute(xml_path, node_name, attr_name, new_value)

  end

end
