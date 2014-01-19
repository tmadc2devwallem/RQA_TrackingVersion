class BizRevision

  def self.create(version, commit_id)
    Revision.create(:version => version, :commit_id => commit_id)
  end

end