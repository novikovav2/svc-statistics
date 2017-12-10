# Author: A. Novikov
#
# Usefull link:
# https://www.ibm.com/support/knowledgecenter/STLM6B_7.8.0/com.ibm.storwize.v3500.780.doc/svc_clusterstartstatswin_20qm0u.html
#


dir = '../iostat/' # Folder for statistics files
influxdb_host = 'localhost' # InfluxDB host
influxdb_db = 'svc' # InfluxDB database


require 'nokogiri'
require 'date'
require 'time'
require 'influxdb'
require 'fileutils'


@influxdb = InfluxDB::Client.new influxdb_db, host: influxdb_host

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

    # idx = vdisk.attr('idx')
    # id = vdisk.attr('id')
    # ro = vdisk.attr('ro')
    # wo = vdisk.attr('wo')
    # rb = vdisk.attr('rb')
    # wb = vdisk.attr('wb')
    # rl = vdisk.attr('rl')
    # wl = vdisk.attr('wl')
    # rlw = vdisk.attr('rlw')
    # wlw = vdisk.attr('wlw')
    # gwo = vdisk.attr('gwo')
    # gwot = vdisk.attr('gwot')
    # gws = vdisk.attr('gws')
    # gwl = vdisk.attr('gwl')
    #
    # common_data = {
    #   timestamp: @timestamp,
    #   tags: {
    #     cluster: @cluster,
    #     cluster_id: @cluster_id,
    #     vdisk_id: idx,
    #     vdisk: id
    #   }
    # }
    #
    # ro_data = { values: { value: ro } }.merge common_data
    # wo_data = { values: { value: wo } }.merge common_data
    # rb_data = { values: { value: rb } }.merge common_data
    # wb_data = { values: { value: wb } }.merge common_data
    # rl_data = { values: { value: rl } }.merge common_data
    # wl_data = { values: { value: wl } }.merge common_data
    # rlw_data = { values: { value: rlw } }.merge common_data
    # wlw_data = { values: { value: wlw } }.merge common_data
    # gwo_data = { values: { value: gwo } }.merge common_data
    # gwot_data = { values: { value: gwot } }.merge common_data
    # gws_data = { values: { value: gws } }.merge common_data
    # gwl_data = { values: { value: gwl } }.merge common_data
    #
    # @influxdb.write_point('vdisk_ro', ro_data)
    # @influxdb.write_point('vdisk_wo', wo_data)
    # @influxdb.write_point('vdisk_rb', rb_data)
    # @influxdb.write_point('vdisk_wb', wb_data)
    # @influxdb.write_point('vdisk_rl', rl_data)
    # @influxdb.write_point('vdisk_wl', wl_data)
    # @influxdb.write_point('vdisk_rlw', rlw_data)
    # @influxdb.write_point('vdisk_wlw', wlw_data)
    # @influxdb.write_point('vdisk_gwo', gwo_data)
    # @influxdb.write_point('vdisk_gwot', gwot_data)
    # @influxdb.write_point('vdisk_gws', gws_data)
    # @influxdb.write_point('vdisk_gwl', gwl_data)
  end
end

# ========================================================================
# Main processing
#

Dir.foreach(dir) do |file|
  next if (file == '.') || (file == '..') || (file == 'old')
  puts file

  f = File.open(dir + file, 'r')

  xml = Nokogiri::XML(f)
  info = xml.css('diskStatsColl')

  @cluster = info.attr('cluster')
  @cluster_id = info.attr('cluster_id')
  @objects_type = info.attr('contains')
  @timestamp = Time.parse(info.attr('timestamp')).to_i

  mdisk_processing(xml) if @objects_type.to_s == 'managedDiskStats'
  vdisk_processing(xml) if @objects_type.to_s == 'virtualDiskStats'

  f.close
  FileUtils.cp(dir + file, dir + 'old/')
  FileUtils.remove(dir + file, :force => true)
end
