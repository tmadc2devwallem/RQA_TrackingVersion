module LoggerHelper
  require 'logger'

  def self.log_error(log_file_name, message, src_file = __FILE__, log_line = __LINE__)
    logger = Logger.new(File.join(Rails.root, 'log', "#{log_file_name}"))
    logger.datetime_format = '%Y-%m-%d %H:%M:%S'
    logger.error('ERROR - ' + src_file.to_s + ' - line ' + log_line.to_s  + ': ' + message)
    logger.close
  end

  def self.log_fatal(log_file_name, message, src_file = __FILE__, log_line = __LINE__)
    logger = Logger.new(File.join(Rails.root, 'log', "#{log_file_name}"))
    logger.datetime_format = '%Y-%m-%d %H:%M:%S'
    logger.fatal('FATAL - ' + src_file.to_s + ' - line ' + log_line.to_s  + ': ' + message)
    logger.close
  end

  def self.log_info(log_file_name, message, src_file = __FILE__, log_line = __LINE__)
    logger = Logger.new(File.join(Rails.root, 'log', "#{log_file_name}"))
    logger.datetime_format = '%Y-%m-%d %H:%M:%S'
    logger.info('INFO - ' + src_file.to_s + ' - line ' + log_line.to_s  + ': ' + message)
    logger.close
  end

  def self.log_debug(log_file_name, message, src_file = __FILE__, log_line = __LINE__)
    logger = Logger.new(File.join(Rails.root, 'log', "#{log_file_name}"))
    logger.datetime_format = '%Y-%m-%d %H:%M:%S'
    logger.debug('DEBUG - ' + src_file.to_s + ' - line ' + log_line.to_s  + ': ' + message)
    logger.close
  end

  def self.log_warn(log_file_name, message, src_file = __FILE__, log_line = __LINE__)
    logger = Logger.new(File.join(Rails.root, 'log', "#{log_file_name}"))
    logger.datetime_format = '%Y-%m-%d %H:%M:%S'
    logger.warn('WARN - ' + src_file.to_s + ' - line ' + log_line.to_s  + ': ' + message)
    logger.close
  end

end