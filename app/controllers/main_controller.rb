class MainController < ApplicationController

  ## dathi
  ## Tracking version
  ## SHORE SIDE
  def run
    JobHelper.track_and_store_version

    #JobHelper.get_latest_code_and_send
  end

end
