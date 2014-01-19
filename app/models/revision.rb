class Revision < ActiveRecord::Base

  establish_connection 'RQA_TRACKING_VERSION'
  self.table_name = 'Revisions'
  self.primary_key = :version

  attr_accessible :version, :commit_id

  has_one :VersionVessel

  validates :version, presence: true
  validates :commit_id, presence: true

end
