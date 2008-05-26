# SimplyVersioned 0.7
#
# Simple ActiveRecord versioning
# Copyright (c) 2007,2008 Matt Mower <self@mattmower.com>
# Released under the MIT license (see accompany MIT-LICENSE file)
#

module SoftwareHeretics
  
  module ActiveRecord
  
    module SimplyVersioned
    
      module ClassMethods
        
        # Marks this ActiveRecord model as being versioned. Calls to +create+ or +save+ will,
        # in future, create a series of associated Version instances that can be accessed via
        # the +versions+ association.
        #
        # Options:
        # +limit+ - specifies the number of old versions to keep (default = nil, never delete old versions)
        #
        # To save the record without creating a version either set +versioning_enabled+ to false
        # on the model before calling save or, alternatively, use +without_versioning+ and save
        # the model from its block.
        #
        def simply_versioned( options = {} )
          options.reverse_merge!( {
            :keep => nil
          })
          
          has_many :versions, :order => 'number DESC', :as => :versionable, :dependent => :destroy, :extend => VersionsProxyMethods

          after_save :simply_versioned_create_version
          
          cattr_accessor :simply_versioned_keep_limit
          self.simply_versioned_keep_limit = options[:keep]
          
          class_eval do
            def versioning_enabled=( enabled )
              self.instance_variable_set( :@simply_versioned_enabled, enabled )
            end
            
            def versioning_enabled?
              enabled = self.instance_variable_get( :@simply_versioned_enabled )
              if enabled.nil?
                enabled = self.instance_variable_set( :@simply_versioned_enabled, true )
              end
              enabled
            end
          end
        end

      end

      # Methods that will be defined on the ActiveRecord model being versioned
      module InstanceMethods
        
        # Revert this model instance to the attributes it had at the specified version number.
        #
        # options:
        # +except+ specify a list of attributes that are not restored (default: created_at, updated_at)
        #
        def revert_to_version( version, options = {} )
          version = if version.kind_of?( Version )
            version
          else
            version = self.versions.find( :first, :conditions => { :number => Integer( version ) } )
          end
          
          options.reverse_merge!({
            :except => [:created_at,:updated_at]
          })
          
          reversion_data = YAML::load( version.yaml )
          reversion_data.delete_if { |key,value| options[:except].include? key.to_sym }
          reversion_data.each do |key,value|
            self.__send__( "#{key}=", value )
          end
        end
        
        # Invoke the supplied block passing the receiver as the sole block argument with
        # versioning enabled or disabled depending upon the value of the +enabled+ parameter
        # for the duration of the block.
        def with_versioning( enabled, &block )
          versioning_was_enabled = self.versioning_enabled?
          self.versioning_enabled = enabled
          begin
            block.call( self )
          ensure
            self.versioning_enabled = versioning_was_enabled
          end
        end
        
        def unversioned?
          self.versions.nil? || self.versions.size == 0
        end
        
        def versioned?
          !unversioned?
        end
        
        protected
        
        def simply_versioned_create_version
          if self.versioning_enabled?
            if self.versions.create( :yaml => self.attributes.to_yaml )
              self.versions.clean_old_versions( simply_versioned_keep_limit.to_i ) if simply_versioned_keep_limit
            end
          end
          true
        end
        
      end

      module VersionsProxyMethods
        
        # Get the Version instance corresponding to this models for the specified version number.
        def get_version( number )
          find_by_number( number )
        end
        
        # Get the first Version corresponding to this model.
        def first_version
          find( :first, :order => 'number ASC' )
        end

        # Get the current Version corresponding to this model.
        def current_version
          find( :first, :order => 'number DESC' )
        end
        
        # If the model instance has more versions than the limit specified, delete all excess older versions.
        def clean_old_versions( versions_to_keep )
          find( :all, :conditions => [ 'number <= ?', self.maximum( :number ) - versions_to_keep ] ).each do |version|
            version.destroy
          end
        end
        
        # Return the Version for this model with the next higher version
        def next_version( number )
          find( :first, :order => 'number ASC', :conditions => [ "number > ?", number ] )
        end
        
        # Return the Version for this model with the next lower version
        def previous_version( number )
          find( :first, :order => 'number DESC', :conditions => [ "number < ?", number ] )
        end
      end

      def self.included( receiver )
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    
    end
  
  end

end

ActiveRecord::Base.send( :include, SoftwareHeretics::ActiveRecord::SimplyVersioned )
