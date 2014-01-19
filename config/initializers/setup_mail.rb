#########################################################################################
#ActionMailer::Base.smtp_settings = {
#    :address              => "smtp.gmail.com",
#    :port                 => 587,
#    :user_name            => "kietfriendly",
#    :password             => "Tuankiet@291185",
#    :authentication       => "plain"
##    :domain               => "railscasts.com",
##    :enable_starttls_auto => true
#}

ActionMailer::Base.smtp_settings = {
    :address              => '192.168.1.21',
    :port                 => 25,
    :domain               => 'tma.com.vn',
    :enable_starttls_auto => false
}

#########################################################################################
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.default_url_options = { :host => 'localhost:3000' }
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.perform_deliveries = true