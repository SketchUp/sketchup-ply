# Copyright 2013 Trimble Navigation Ltd.
#
# License: Apache License, Version 2.0
#
# A SketchUp Ruby Extension that adds PLY file format
# import and export. More info at https://github.com/SketchUp/sketchup-ply

require 'sketchup.rb'
require 'extensions.rb'

module CommunityExtensions
  module PLY
  
    PLUGIN_ROOT_PATH    = File.dirname(__FILE__)
    PLUGIN_PATH         = File.join(PLUGIN_ROOT_PATH, 'sketchup-ply')
    PLUGIN_STRINGS_PATH = File.join(PLUGIN_PATH, 'strings')
    
    Sketchup::require File.join(PLUGIN_PATH, 'translator')
    options = {
      :custom_path => PLUGIN_STRINGS_PATH,
      :debug => false
    }
    @translator = Translator.new('PLY.strings', options)
    
    # Method for easy access to the translator instance to anything within this
    # project.
    # 
    # @example
    #   PLY.translate('Hello World')
    def self.translate(string)
      @translator.get(string)
    end
  
    extension = SketchupExtension.new(
      PLY.translate('PLY Import & Export'),
      File.join(PLUGIN_PATH, 'loader.rb')
    )
    
    extension.description = PLY.translate(
      'Adds PLY file format import and export. ' <<
      'This is an open source project sponsored by the SketchUp team. More ' <<
      'info and updates at https://github.com/SketchUp/sketchup-ply'
    )
    extension.version = '0.0.1'
    extension.copyright = '2013 Trimble Navigation, released under Apache 2.0'
    extension.creator = 'J. Foltz, SketchUp Team'
        
    Sketchup.register_extension(extension, true)
    
  end # module PLY
end # module CommunityExtensions
