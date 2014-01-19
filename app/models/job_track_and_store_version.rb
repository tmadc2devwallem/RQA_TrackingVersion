class JobTrackAndStoreVersion < Struct.new(:param)

  require 'timeout'

  def perform
    # free memory
    GC.start

    # Tracking version at Shore side
    begin
      Timeout.timeout(180) do
        begin
          LoggerHelper.log_info('tracking_version.log', '###### Read zipped file to get version.')
          array_= JobHelper.track_and_store_version
          LoggerHelper.log_info('tracking_version.log', '###### Store to database.')
        rescue => e
          puts '!!!! HOOD - error at main part: ' + e.to_s
          LoggerHelper.log_error('tracking_version.log', e.to_s)
        end
      end
    rescue Timeout::Error => e
      puts '!!!! GOC3CHOP - error at perform: ' + e.to_s
      LoggerHelper.log_error('tracking_version.log', e.to_s)
    end
  end

end