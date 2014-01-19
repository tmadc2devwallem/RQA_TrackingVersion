class VersionVessel

  establish_connection 'RQA_TRACKING_VERSION'
  self.table_name = 'VersionVessels'
  self.primary_key = :vessel_code

  attr_accessible :vessel_code, :revision_version

  belongs_to :Revision

  validates :vessel_code, presence: true
  validates :revision_version, presence: true

end