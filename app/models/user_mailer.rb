class UserMailer < ActionMailer::Base

  helper :users

  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
  
    @body[:url]  = "#{ENV['SITE_URL']}/activate_user/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "#{ENV['SITE_URL']}/"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "#{ENV['ADMINEMAIL']}"
      @subject     = "[SCEM] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
