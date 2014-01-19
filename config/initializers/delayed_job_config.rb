require 'logger'
Delayed::Job.establish_connection 'RQA_BACKGROUND_JOB'
Delayed::Job.table_name = 'DelayedJobs'
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_attempts = 1

logger = Logger.new(File.join(Rails.root, 'log', 'dj.log'))
logger.datetime_format = '%Y-%m-%d %H:%M:%S'
logger.level = Logger::ERROR
Delayed::Worker.logger = logger
