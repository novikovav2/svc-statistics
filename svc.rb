# Author: A. Novikov
#
# Useful link:
# https://www.ibm.com/support/knowledgecenter/STLM6B_7.8.0/com.ibm.storwize.v3500.780.doc/svc_clusterstartstatswin_20qm0u.html
#

#dir = '../iostat/' # Folder for statistics files
dir = ENV['SVC_STATS_FOLDER'] # Path for folder with stats files
influxdb_host = ENV['SVC_INFLUX_HOST'] # InfluxDB host
influxdb_db = ENV['SVC_INFLUX_DB'] # InfluxDB database

require 'nokogiri' 			# for parsing XML
require 'date'
require 'time'
require 'influxdb'
require 'fileutils'

@influxdb = InfluxDB::Client.new influxdb_db, host: influxdb_host

# ========= MDISK statistics ===============================
def mdisk_processing(xml)
  mdisks = xml.css('mdsk')
  mdisks.each do |mdisk|
    mdisk.attributes.each do |attr, value|
      next if (attr.to_s == 'idx') || (attr.to_s == 'id')
      data = {
        values: { value: value.value.to_i },
        timestamp: @timestamp,
        tags: {
          cluster: @cluster,
          cluster_id: @cluster_id,
          mdisk_id: mdisk.attr('idx').to_i,
          mdisk: mdisk.attr('id')
        }
      }
      @influxdb.write_point('mdisk_' + attr, data)
    end
  end
end
#==========END MDISK ==================================


#===========VDISK statistics =============================
def vdisk_processing(xml)
  vdisks = xml.css('vdsk')
  vdisks.each do |vdisk|
    vdisk.attributes.each do |attr, value|
      next if (attr.to_s == 'idx') || (attr.to_s == 'id')
      data = {
        values: { value: value.value.to_i },
        timestamp: @timestamp,
        tags: {
          cluster: @cluster,
          cluster_id: @cluster_id,
          vdisk_id: vdisk.attr('idx').to_i,
          vdisk: vdisk.attr('id')
        }
      }
      @influxdb.write_point('vdisk_' + attr, data)
    end
  end
end
#===========END VDISK ================================

# ========================================================================
# Main processing
# ========================================================================

Dir.foreach(dir) do |file|
  next if (file == '.') || (file == '..') 

  f = File.open(dir + file, 'r')

  xml = Nokogiri::XML(f)
  info = xml.css('diskStatsColl')

  @cluster = info.attr('cluster')
  @cluster_id = info.attr('cluster_id')
  @objects_type = info.attr('contains')
  @timestamp = Time.parse(info.attr('timestamp')).to_i

  mdisk_processing(xml) if @objects_type.to_s == 'managedDiskStats' #processing MDISK statistics
  vdisk_processing(xml) if @objects_type.to_s == 'virtualDiskStats' #processing VDISK statistics

  f.close
  FileUtils.remove(dir + file, force: true) #remove processed file
end

# =======================================================================
# END Main 
#========================================================================
