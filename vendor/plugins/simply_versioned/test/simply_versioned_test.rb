require File.join( File.dirname( __FILE__ ), 'test_helper' )

require 'mocha'

class Aardvark < ActiveRecord::Base
  simply_versioned :keep => 3
end

class Gnu < ActiveRecord::Base
  simply_versioned :keep => 4
end

class Undine < ActiveRecord::Base
end

class SimplyVersionedTest < FixturedTestCase
  
  def self.suite_setup
    ActiveRecord::Schema.define do
      create_table :aardvarks, :force => true do |t|
        t.string :name
        t.integer :age
      end
      
      create_table :gnus, :force => true do |t|
        t.string :name
        t.text :description
      end
      
      create_table :undines, :force => true do |t|
        t.string :name
        t.integer :married, :default => 0
      end
      
      create_table :versions, :force => true do |t|
        t.integer   :versionable_id
        t.string    :versionable_type
        t.integer   :number
        t.text      :yaml
        t.datetime  :created_at
      end
    end
  end
  
  def self.suite_teardown
    ActiveRecord::Schema.define do
      drop_table :versions
      drop_table :gnus
      drop_table :aardvarks
    end
  end
  
  def test_should_start_with_empty_versions
    anthony = Aardvark.new( :name => 'Anthony', :age => 35 )
    assert anthony.versions.empty?
    assert anthony.unversioned?
  end
  
  def test_should_be_versioned
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 )
    assert anthony.versioned?
  end
  
  def test_should_get_versions
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 )
    anthony.age += 1
    anthony.save!
    
    assert_equal 35, anthony.versions.get_version(1).model.age
    assert_equal 36, anthony.versions.get_version(2).model.age
  end
  
  def test_should_version_on_create
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 )
    assert_equal 1, anthony.versions.count
    assert_equal 1, anthony.versions.current_version.number
  end
  
  def test_should_version_on_save
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 )
    anthony.age += 1
    anthony.save!
    assert_equal 2, anthony.versions.count
  end
  
  def test_should_trim_versions
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 ) # v1
    anthony.age += 1
    anthony.save! #v2
    
    anthony.age += 1
    anthony.save! #v3
    
    anthony.age += 1
    anthony.save! #v4 !!
    
    assert_equal 3, anthony.versions.count
    assert_equal 36, anthony.versions.first_version.model.age
    assert_equal 38, anthony.versions.current_version.model.age
  end
  
  def test_should_revert
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 ) # v1
    anthony.age += 1
    anthony.save! #v2
    
    anthony.revert_to_version( 1 )
    assert_equal 35, anthony.age
  end
  
  def test_should_revert_except
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 ) # v1
    
    anthony.name = "Tony"
    anthony.age = 45
    anthony.save! # v2
    
    anthony.revert_to_version( 1, :except => [:name,:created_at,:updated_at] )
    assert_equal "Tony", anthony.name
    assert_equal 35, anthony.age
  end
  
  def test_should_delete_dependent_versions
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 ) # v1
    anthony.age += 1
    anthony.save! #v2
    
    assert_difference( 'Version.count', -2 ) do
      anthony.destroy
    end
  end
  
  def test_should_isolate_versioned_models
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 )
    gary = Gnu.create!( :name => 'Gary', :description => 'Gary the GNU' )
    
    assert_equal 2, Version.count
    assert_equal 1, anthony.versions.first.number
    assert_equal 1, gary.versions.first.number
  end
  
  def test_should_be_able_to_control_versioning
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 ) # v1

    assert_no_difference( 'anthony.versions.count' ) do
      anthony.age += 1
      anthony.with_versioning( false, &:save! )
    end
    
    assert_difference( 'anthony.versions.count' ) do
      anthony.age += 1
      anthony.with_versioning( true, &:save! )
    end
  end
  
  def test_should_not_version_in_block
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 ) # v1
    
    assert_no_difference( 'anthony.versions.count' ) do
      anthony.age += 1
      anthony.with_versioning( false ) do
        anthony.save!
      end
    end
  end
  
  def test_should_begin_versioning_existing_record
    ulrica = Undine.create!( :name => 'Ulrica' )
    
    # Now we begin versioning this kind of record
    Undine.class_eval do
      simply_versioned
    end
    
    ulrica = Undine.find_by_name( 'Ulrica' )
    assert ulrica.unversioned?
    
    ulrica.update_attributes( :married => 1 )    
    assert !ulrica.unversioned?
    assert_equal 1, ulrica.versions.size
    assert_equal 1, ulrica.versions.first.model.married
  end
  
  def test_should_follow_back_and_forth
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 ) # v1
    anthony.age += 1
    anthony.save! #v2
    anthony.age += 1
    anthony.save!
    
    assert_equal anthony.versions.current_version, anthony.versions.first_version.next.next
    assert_equal anthony.versions.first_version, anthony.versions.current_version.previous.previous
  end
  
  def test_should_be_trustworthy_collection
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 ) # v1
    anthony.age += 1
    anthony.save! #v2
    
    # Now create another record
    
    alan = Aardvark.create!( :name => 'Alan', :age => 35 )
    assert_equal 1, alan.versions.size
  end
  
  def test_should_not_delete_old_versions_by_default
    ulrica = Undine.create!( :name => 'Ulrica' )
    ulrica.versions.expects( :clean_old_versions ).never
    100.times do
      ulrica.update_attribute( :married, 1 - ulrica.married )
    end
  end
  
end
