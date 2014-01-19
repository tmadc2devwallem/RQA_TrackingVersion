require 'clockwork'
require './config/boot'
require './config/environment'
require 'delayed_job_active_record'

module Clockwork

  every(240.seconds, '1. Tracking folder to get new income attachment.') {
    Delayed::Job.enqueue JobTrackAndStoreVersion.new('Tracking zipped files in folder under background job.'),
                         :priority => 1
  }

  every(1.day, '2. Get head revision then send all changed files to ship.') {
    Delayed::Job.enqueue JobSendLatestCode.new('Tracking zipped files in folder under background job.'),
                         :priority => 2
  }

  every(1.day, '3. Clear RAM Job') {
    GC.start
  }

end