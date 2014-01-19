class JobSendLatestCode < Struct.new(:param)

  require 'timeout'

  def perform
    # free memory
    GC.start

    begin
      Timeout.timeout(180) do
        begin
         JobHelper.get_latest_code_and_send
        rescue => e
          puts 'Error at main part: ' + e.to_s
          LoggerHelper.log_error('tracking_version.log', e.to_s)
        end
      end
    rescue Timeout::Error => e
      puts 'Error at perform: ' + e.to_s
      LoggerHelper.log_error('tracking_version.log', e.to_s)
    end
  end

end