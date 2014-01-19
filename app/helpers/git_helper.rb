module GitHelper

  require 'git'

  def self.open(local_path)
    begin
      git_instance = Git.open(local_path)
    rescue => ex
      puts ex
      git_instance = nil
    end
    if git_instance.nil?
      git_instance = clone(File.expand_path('..', local_path))
    end
    return git_instance
  end

  def self.clone(local_path)
    begin
      git_instance = Git.clone(ApplicationHelper::GIT_URI,
                               ApplicationHelper::RQA_FOLDER,
                               :path => local_path)
    rescue => ex
      puts ex
      git_instance = nil
    end
    return git_instance
  end

  def self.get_changed_files(ship_revision, local_path)
    begin
      # Get Git object
      git_instance = open(local_path)
      if !git_instance.nil?
        puts 'Current directory: ' + Dir.pwd
        Dir.chdir(local_path) do
          puts 'Execute change directory to: ' + local_path
          puts 'Now, current directory is: ' + Dir.pwd

          # Get latest code
          git_instance.pull

          # Get head revision
          head_revision = git_instance.log(1)
          # Get all revision from 'ship_revision' to 'head_revision'
          diff_files = git_instance.diff(ship_revision, head_revision).stats
          return diff_files
        end
      end
    rescue => ex
      puts ex
      return nil
    end
  end

  def self.get_head(local_path)
    git_instance = open(local_path)
    return git_instance.object('HEAD')
  end

end
