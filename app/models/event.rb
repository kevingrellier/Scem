class Event < ActiveRecord::Base
  include SharedMethods
  before_validation :remove_whitespace_from_name

  has_friendly_id :name, :use_slug => true, :reserved => ["new","edit"]

  has_many :galleries, :as => :parent, :dependent => :destroy

  has_one :picture, :as => :parent, :dependent => :destroy, :conditions => "pictures.state = 'active'"

  has_many :posts, :as => :parent, :dependent => :destroy

  def search_posts(search, page)
    posts.paginate :per_page => ENV['PER_PAGE'], :page => page,
      :conditions => ['name like ?',"%#{search}%"],
      :order => 'created_at DESC'
  end

  def search_posts_by_state(search, page, state)
    posts.paginate :per_page => ENV['PER_PAGE'], :page => page,
      :conditions => ['name like ? and state=?', "%#{search}%", state],
      :order => 'created_at DESC'
  end

  acts_as_commentable

  acts_as_rateable

  validates_presence_of :name, :description_short
  validates_length_of :description_short, :maximum=>800

  
  has_many :terms
  has_and_belongs_to_many :categories#, :conditions => "categories.to_display = true"


  has_many :contributions
  has_many :organisms, :through => :contributions, :uniq => true

  with_options :through => :contributions, :source => :organism do |obj|
    obj.has_many :publishers, :conditions => "contributions.role = 'publisher'"
    obj.has_many :organizers, :conditions => "contributions.role = 'organizer'"
    obj.has_many :partners, :conditions => "contributions.role = 'partner'"
    obj.has_many :places, :conditions => "contributions.role = 'place'"
  end


  #MANAGE TERMS
  #validates_associated :terms

  after_update :save_terms


  def new_term_attributes=(term_attributes)
    term_attributes.each do |attributes|
      if attributes['description'].blank?
        attributes['description'] = ''
      end
      #raise attributes.inspect
      attributes = parse_my_date(attributes)
      #raise attributes.inspect
      terms.build(attributes)
    end
  end

  def existing_term_attributes=(term_attributes)
    terms.reject(&:new_record?).each do |term|
      attributes = term_attributes[term.id.to_s]
      if attributes
        term.attributes = parse_my_date(attributes)
      else
        terms.delete(term)
      end
    end
  end

  def save_terms
    terms.each do |term|
      term.save(false)
    end
  end

  #MANAGE CONTRIBUTIONS
  validates_associated :contributions

  
  def self.search_has_publisher(search, page, is_private=false)
    paginate :per_page => ENV['PER_PAGE'], :page => page,
      :joins => "inner join contributions on contributions.event_id = events.id and contributions.role='publisher'",
      :conditions => ["events.name like ? and events.is_private = ?", "%#{search}%", is_private],
      :order => 'events.name',
      :group => 'events.id'
  end

  def self.search_not_have_publisher(search, page, is_private=false)
    paginate :per_page => ENV['PER_PAGE'], :page => page,
      :conditions => ["events.name like ? and events.is_private = ? and events.id not in (select event_id from contributions where role='publisher' and event_id is not null)", "%#{search}%", is_private],
      :order => 'events.name'
  end

  def self.search(search, page, is_private=false)
    paginate :per_page => ENV['PER_PAGE'], :page => page,
      :conditions => ['name like ? and events.is_private = ?', "%#{search}%", is_private],
      :order => 'name'
  end

  def search_galleries(search, page)
    galleries.paginate :per_page => ENV['PER_PAGE'], :page => page,
      :conditions => ['name like ?', "%#{search}%"],
      :order => 'name'
  end


  # in the future we can change the select to have many publisher per event
  #but now we want to restrict to just one
  def get_first_publisher
    self.publishers.all.first.id unless self.publishers.all.first.nil?
  end

  def get_first_place
    self.places.all.first.id unless self.places.all.first.nil?
  end
  


  def is_granted_to_view?(user)
    result = false

    if(user.has_system_role("moderator"))
      result = true
    end

    if(created_by==user.id)
      result = true
    end

    self.publishers.each do |organism|
      if organism.is_user_member?(user)
        result = true
      end
    end

    self.organizers.each do |organism|
      if organism.is_user_member?(user)
        result = true
      end
    end


    self.partners.each do |organism|
      if organism.is_user_member?(user)
        result = true
      end
    end
   
    return result
  end

  def is_granted_to_edit?(user)
    result = false

    if(user.has_system_role("moderator"))
      result = true
    end

    if(created_by==user.id)
      result = true
    end

    self.publishers.each do |organism|
      if organism.is_user_moderator?(user)
        result = true
      end
    end

    #NOTE:uncomment if you want the organizers allowed to edit event
    #    self.organizers.each do |organism|
    #      if organism.is_user_moderator?(user)
    #        result = true
    #      end
    #    end

    #NOTE:uncomment if you want the partners allowed to edit event
    #    self.partners.each do |organism|
    #      if organism.is_user_moderator?(user)
    #        result = true
    #      end
    #    end

    return result
  end

  def get_moderators_list
    puts "build the moderators list of the event..."
    moderators_list = Array.new
    self.publishers.each do |organism|
      moderators_list +=organism.get_moderators_list
    end
    moderators_list
  end

  #Note: method exactly equal to is_granted_to_edit?, the is something to improve ....
  def is_user_moderator?(user)
    result = false
    if(user)
      if  user.has_system_role('moderator')
        result = true
      end


      if(created_by==user.id)
        result = true
      end

      self.publishers.each do |organism|
        if organism.is_user_moderator?(user)
          result = true
        end
      end
    end
    return result
	
  end

  def is_user_member?(user)
    result = false


    self.publishers.each do |organism|
      if organism.is_user_member?(user)
        result = true
      end
    end
    return result
  end

  def list_participants
    list = Array.new
    terms.each do |term|
      list += term.sure_participants + term.maybe_participants
    end
    return list
  end

  # very very bad method
  def get_parent_object
    nil
  end

  def get_picture_root_path
    return 'events/'+id.to_s
  end

  private
  def parse_my_date(attributes)
    attributes[:end] = Time.parse(attributes[:end])
    attributes[:start] = Time.parse(attributes[:start])
    return attributes
  end
end

