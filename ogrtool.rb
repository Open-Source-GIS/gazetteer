#!/usr/bin/env ruby

require 'rubygems'
require 'thor'

# A tool for performing simple tasks with OGR.

class OgrTool < Thor

  desc "clip", "Clip an area from a shapefile. Use 'x_min y_min x_max y_max' notation to define the bounding box."
  method_option :boundingbox, :aliases => '-b', :desc => "Define the bounding area (e.g. \"498438 395921 566498 471747\")", :required => true
  method_option :file, :aliases => '-f', :desc => "File to clip an area from", :required => true
  def clip
    input_file = options[:file]
    output_file = "#{File.join(File.dirname(options[:file]), File.basename(options[:file], File.extname(options[:file])))}_clip.shp"
    bb = options[:boundingbox]
    `ogr2ogr -f "ESRI Shapefile" #{output_file} #{input_file} -clipsrc #{bb}`
  end

  desc "topg", "Import a GIS data file into PostGIS."
  method_option :file, :aliases => '-f', :desc => "File to import", :required => true
  method_option :layer, :aliases => '-l', :desc => "Layer name to import"
  method_option :host, :aliases => '-h', :desc => "Database server hostname", :required => true, :default => "localhost"
  method_option :user, :aliases => '-u', :desc => "Username to connect to database", :required => true , :default => "postgres"
  method_option :dbname, :aliases => '-d', :desc => "PostGIS database to connect to", :required => true
  method_option :port, :aliases => '-p', :desc => "PostgreSQL server port number", :default => "5432"
  method_option :type, :aliases => '-t', :desc => "Cast to a new layer type, such as multipolygon or multilinestring"
  method_option :geometry, :aliases => '-g', :desc => "Set a custom geometry column name"
  method_option :overwrite, :aliases => '-O', :desc => "Overwrite current layer(s)", :type => :boolean
  method_option :skipfailures, :aliases => '-S', :desc => "Skip failed row imports", :type => :boolean
  def topg
  	db_connection = "\"host=#{options[:host]} dbname=#{options[:dbname]} user=#{options[:user]} port=#{options[:port]}\""
  	layer = options[:layer] if options[:layer]
  	nlt = "-nlt #{options[:type]}"
  	lco = "-lco GEOMETRY_NAME=#{options[:geometry]}" if options[:geometry]
  	overwrite = "-overwrite" if options[:overwrite]
  	skipfailures = "-skipfailures" if options[:skipfailures]
  	puts "ogr2ogr -f \"PostgreSQL\" PG:#{db_connection} #{options[:file]} #{layer} #{nlt} #{lco} #{overwrite} #{skipfailures}"
  end

  desc "shproject", "Reproject a shapefile using source and destination SRS EPSG codes."
  method_option :inputfile, :aliases => '-f', :desc => "File to reproject", :required => true
  method_option :s_srs, :aliases => '-s', :desc => "Source data SRS"
  method_option :t_srs, :aliases => '-t', :desc => "Destination data SRS"
  def shproject
  	input_file = options[:inputfile]
  	output_file = "#{File.join(File.dirname(options[:inputfile]), File.basename(options[:inputfile], File.extname(options[:inputfile])))}_project.shp"

  	`ogr2ogr -f "ESRI Shapefile" -s_srs EPSG:#{options[:s_srs]} -t_srs EPSG:#{options[:t_srs]} #{output_file} #{input_file}`
  end

  desc "features", "Get the feature count for a dataset."
  method_option :file, :aliases => '-f', :desc => "File to count features from", :required => true
  method_option :layer, :aliases => '-l', :desc => "Layer name"
  def features
    puts `ogrinfo -so -al #{options[:file]} #{options[:layer]} | grep -w "Feature Count" | sed 's/Feature Count: //g'`
  end

  desc "shpgeom", "Get the geometry type for a shapefile."
  method_option :file, :aliases => '-f', :desc => "File to get geometry from", :required => true
  def shpgeom
    file = options[:file]
    basename = "#{File.basename(options[:file], File.extname(options[:file]))}"
    puts `ogrinfo -so #{file} #{basename} | grep -w Geometry | sed 's/Geometry: //g'`
  end
  
end

OgrTool.start