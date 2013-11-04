class Thing < ActiveRecord::Base
  
  has_many :pieces
  
  attr_accessible :int, :str
  
  validates_presence_of :str
  validates_numericality_of :int
  
  def wake_destroyable?
    true
  end
end
