module Stead
  class EadGenerator
    attr_accessor :csv, :ead, :template, :series, :subseries, :component_parts

    def initialize(opts = {})
      @csv = opts[:csv] || nil

      @template = pick_template(opts)
      @eadid = opts[:eadid] if opts[:eadid]
      @base_url = opts[:base_url] if opts[:base_url]
      # component_parts are the rows in the csv file
      @component_parts = csv_to_a
    end

    def pick_template(opts)
      if opts[:template]
        Nokogiri::XML(File.read(opts[:template]))
      else
        Stead.ead_template_xml
      end
    end

    def self.from_csv(csv, opts={})
      lines = csv.split(/\r\n|\n|\r/)
      # trim empty lines
      cleaned_lines = lines.select do |line|
        !line.strip.empty?
      end
      csv = cleaned_lines.join("\n")
      self.new(opts.merge(:csv => csv))
    end

    def eadid_node
      @ead.xpath('//xmlns:eadid').first
    end

    def add_eadid
      eadid_node.content = @eadid
    end

    def add_eadid_url
      if @base_url
        eadid_node['url'] = File.join(@base_url, @eadid)
      elsif @url
        eadid_node['url'] = @url
      end
    end

    def to_ead
      @ead = template.dup
      add_eadid
      add_eadid_url
      @dsc = @ead.xpath('//xmlns:archdesc/xmlns:dsc')[0]
      if series?
        add_series
        add_subseries if subseries?
      end
      @component_parts.each do |cp|
        c = node(file_component_part_name(cp))
        c['level'] = 'file'
        c['audience'] = 'internal' if !cp['internal only'].nil?
        did = node('did')
        c.add_child(did)
        add_did_nodes(cp, did)
        add_dao(cp, did)
        add_physdescs(cp, did)
        add_containers(cp, did)
        add_language(cp, did)
        add_scopecontent(cp, did)
        add_accessrestrict(cp, did)
        add_controlaccess(cp, c)
        add_file_component_part(cp, c)
      end
      begin
        valid?
      rescue Stead::InvalidEad
        warn "Invalid EAD"
        ead
      end
      ead
    end

    def add_series
      add_arrangement
      series = @component_parts.map do |cp|
        [cp['series number'], cp['series title'], cp['series dates'], cp['series scopecontent'], cp['series extent'], cp['series bioghist']]
      end.uniq
      series.each do |ser|
        add_arrangement_item(ser)
        # create series node and add to dsc
        series_node = node('c01')
        @dsc.add_child(series_node)
        series_node['level'] = 'series'
        # create series did and add to series node
        series_did = node('did')
        series_node.add_child(series_did)
        unitid = node('unitid')
        unitid.content = ser[0]
        unittitle = node('unittitle')
        unittitle.content = ser[1]
        unitdate = node('unitdate')
        unitdate.content = ser[2]
        series_did.add_child(unitid)
        series_did.add_child(unittitle)
        series_did.add_child(unitdate)
        unless ser[3].nil?
          scopecontent = node('scopecontent')
          p = node('p')
          p.content = ser[3]
          scopecontent.add_child(p)
          series_node.add_child(scopecontent)
        end
        unless ser[4].nil?
          physdesc = node('physdesc')
          extent = node('extent')
          extent.content = ser[4]
          series_did.add_child(physdesc)
          physdesc.add_child(extent)
        end
        unless ser[5].nil?
          bioghist = node('bioghist')
          head = node('head')
          head.content = 'Administrative History'
          p = node('p')
          p.content = ser[5]
          bioghist.add_child(head)
          bioghist.add_child(p)
          series_node.add_child(bioghist)
        end
      end
    end

    def add_subseries
      @component_parts.each do |cp|
        if !cp['subseries number'].nil?
          series_list =    @dsc.xpath("xmlns:c01/xmlns:did/xmlns:unitid[text()='#{cp['series number']}']")
          subseries_list = @dsc.xpath("xmlns:c01/xmlns:c02[@level='subseries']/xmlns:did/xmlns:unitid[text()='#{cp['subseries number']}']")
          if series_list.length == 1 and subseries_list.length == 0
            series = series_list.first.parent.parent
            subseries_node = node('c02')
            series.add_child(subseries_node)
            subseries_node['level'] = 'subseries'
            # create series did and add to subseries node
            # FIXME: DRY this up with add_series
            subseries_did = node('did')
            subseries_node.add_child(subseries_did)
            unitid = node('unitid')
            unitid.content = cp['subseries number']
            unittitle = node('unittitle')
            unittitle.content = cp['subseries title']
            unitdate = node('unitdate')
            unitdate.content = cp['subseries dates']
            subseries_did.add_child(unitid)
            subseries_did.add_child(unittitle)
            subseries_did.add_child(unitdate)
          end
        end
      end
    end

    def add_arrangement
      arrangement = node('arrangement')
      head = node('head')
      head.content = 'Organization of the Collection'
      arrangement.add_child(head)
      p = node('p')
      p.content = 'This collection is organized into series:'
      arrangement.add_child(p)
      list = node('list')
      p.add_child(list)
      @dsc.add_previous_sibling(arrangement)
    end

    def add_arrangement_item(ser)
      list = @ead.xpath('//xmlns:arrangement/xmlns:p/xmlns:list').first
      item = node('item')
      contents = []
      ser[0..2].each do |ser_part|
        contents << ser_part unless ser_part.nil? or ser_part.empty?
      end
      item.content = contents.join(', ')
      list.add_child(item)
    end

    # metadata is a hash from the @component_part and c is the actual node
    def add_file_component_part(metadata, c)
      if !metadata['subseries number'].nil?
        current_subseries = find_current_subseries(metadata)
        current_subseries.add_child(c)
      elsif series?
        current_series = find_current_series(metadata)
        current_series.add_child(c)
      else
        @dsc.add_child(c)
      end
    end

    def find_current_series(cp)
      series_number = cp['series number']
      @ead.xpath("//xmlns:c01/xmlns:did/xmlns:unitid").each do |node|
        return node.parent.parent if node.content == series_number
      end
    end

    def find_current_subseries(cp)
      @ead.xpath("//xmlns:c02/xmlns:did/xmlns:unitid[text()='#{cp['subseries number']}']").each do |node|
        return node.parent.parent if node.content == cp['subseries number']
      end
    end

    def file_component_part_name(cp)
      if !cp['subseries number'].nil?
        'c03'
      elsif series?
        'c02'
      else
        'c01'
      end
    end

    def add_did_nodes(cp, did)
      field_map.each do |header, element|
        if !cp[header].nil?
          if element.is_a? String
            node = node(element)
            node.content = cp[header]
            did.add_child(node)
          elsif element.is_a? Array
            node1 = node(element[0])
            did.add_child(node1)
            node2 = node(element[1])
            node1.add_child(node2)
            node2.content = cp[header]
          elsif element.is_a? Hash
            element.each do |key, value|
              # puts "it's a hash!"
              node = did.xpath(key).first
              if !node
                node = node(key)
                did.add_child(node)
              end
              node[value] = cp[header]
            end
          end
        end
      end
    end

    def add_physdescs(cp, did)
      ['1', '2', '3', '4', '5', '6', '7', '8', '9'].each do |physdesc_number|
        physdesc = cp['physdesc' + physdesc_number]
        dimensions = cp['dimensions' + physdesc_number]
        physfacet = cp['physfacet' + physdesc_number]
        unless (physdesc.nil? or physdesc.empty?) and (dimensions.nil? or dimensions.empty?)
          physdesc_node = node('physdesc')
          unless physdesc.nil? or physdesc.empty?
            physdesc_node['label'] = 'General Physical Description note'
            physdesc_node.content = physdesc
          end
          unless dimensions.nil? or dimensions.empty?
            dimensions_node = node('dimensions')
            dimensions_node.content = dimensions
            physdesc_node.add_child(dimensions_node)
          end
          did.add_child(physdesc_node)
        end
        unless physfacet.nil? or physfacet.empty?
          physdesc_node = node('physdesc')
          physdesc_node['label'] = 'Other Physical Details note'
          physdesc_node.content = physfacet
          did.add_child(physdesc_node)
        end
      end
    end

    def add_language(cp, did)
      unless cp['langcode'].nil? or cp['langcode'].empty?
        langmaterial_node = node('langmaterial')
        language_node = node('language')
        language_node['langcode'] = cp['langcode']
        langmaterial_node.add_child(language_node)
        did.add_child(langmaterial_node)
      end
    end

    def add_containers(cp, did)
      ['1', '2', '3'].each do |container_number|
        container_type = cp['container ' + container_number + ' type']
        container_number = cp['container ' + container_number + ' number']
        if !container_type.nil? and !container_number.nil? and !container_type.empty? and !container_number.empty?
          container_type.strip!
          unless valid_container_type?(container_type)
            if !valid_container_type?(container_type.downcase)
              raise Stead::InvalidContainerType, %Q{"#{container_type}"}
            else
              container_type = container_type.downcase
            end
          end
          container = node('container')
          container['type'] = container_type
          container['label'] = cp['instance type'] if cp['instance type']
          container.content = container_number
          did.add_child(container)
        end
      end
    end

    def add_controlaccess(cp, component_part)
      ['geogname', 'corpname', 'famname', 'name', 'persname', 'subject', 'genreform'].each do |controlaccess_type|
        if cp[controlaccess_type]
          controlaccess = component_part.xpath('controlaccess').first
          if !controlaccess
            controlaccess = node('controlaccess')
          end
          controlaccess_element = node(controlaccess_type)
          controlaccess_element.content = cp[controlaccess_type]
          if !cp[controlaccess_type + '_source'].nil?
            controlaccess_element['source'] = cp[controlaccess_type + '_source']
          end
          if !cp[controlaccess_type + '_role'].nil?
            controlaccess_element['role'] = cp[controlaccess_type + '_role']
          end
          controlaccess.add_child(controlaccess_element)
          component_part.add_child(controlaccess)
        end
        (1..9).each do |the_iterate|
          if cp[controlaccess_type + " " + the_iterate.to_s]
            controlaccess = component_part.xpath('controlaccess').first
            if !controlaccess
              controlaccess = node('controlaccess')
            end
            controlaccess_element = node(controlaccess_type)
            controlaccess_element.content = cp[controlaccess_type + " " + the_iterate.to_s]
            if !cp[controlaccess_type + " " + the_iterate.to_s + ' source'].nil?
              controlaccess_element['source'] = cp[controlaccess_type + " " + the_iterate.to_s + ' source']
            end
            if !cp[controlaccess_type + " " + the_iterate.to_s + ' role'].nil?
              controlaccess_element['role'] = cp[controlaccess_type + " " + the_iterate.to_s + ' role']
            end
            controlaccess.add_child(controlaccess_element)
            component_part.add_child(controlaccess)
          end
        end
      end
    end

    def valid_container_type?(container_type)
      if Stead::CONTAINER_TYPES.include?(container_type)
        return true
      else
        return false
      end
    end

    def add_dao(cp, did)
      unless cp['dao href'].nil? or ( cp['file title'].nil? and cp['dao title'].nil? )
        dao = node('dao')
        daodesc = node('daodesc')
        p = node('p')
        if cp['dao title'].nil?
          dao['ns2:title'] = cp['file title']
          p.content = cp['file title']
          unless cp['file dates'].nil?
            p.content << ", " + cp['file dates']
          end
        else
          dao['ns2:title'] = cp['dao title']
          p.content = cp['dao title']
        end
        unless cp['dao actuate'].nil?
          dao['ns2:actuate'] = cp['dao actuate']
        end
        unless cp['dao show'].nil?
          dao['ns2:show'] = cp['dao show']
        end
        unless cp['dao role'].nil?
          dao['ns2:role'] = cp['dao role']
        end
        dao['ns2:href'] = cp['dao href']
        daodesc.add_child(p)
        dao.add_child(daodesc)
        did.add_next_sibling(dao)
      end
    end

    def add_scopecontent(cp, did)
      unless cp['scopecontent'].nil?
        scopecontent = node('scopecontent')
        p = node('p')
        p.content = cp['scopecontent']
        scopecontent.add_child(p)
        did.add_next_sibling(scopecontent)
      end
    end

    def add_accessrestrict(cp, did)
      unless cp['conditions governing access'].nil?
        accessrestrict = node('accessrestrict')
        p = node('p')
        p.content = cp['conditions governing access']
        accessrestrict.add_child(p)
        did.add_next_sibling(accessrestrict)
      end
    end

    def node(element)
      Nokogiri::XML::Node.new(element, @ead)
    end

    def field_map
      {'file id' => 'unitid',
        'file title' => 'unittitle',
        'file dates' => 'unitdate',
        'file dates type' => {'unitdate' => 'type'},
        'file dates normal' => {'unitdate' => 'normal'},
        'extent' => ['physdesc', 'extent'],
        'physloc' => 'physloc',
        'note1' => ['note', 'p'],
        'note2' => ['note', 'p'],
        'note3' => ['note', 'p']
      }
    end

    def csv_to_a
      a = []
      CSV.parse(csv, :headers => :first_row) do |row|
        a << row.to_hash
      end
      if a.first.keys.include?(nil)
        raise Stead::InvalidCsv
      end
      if !a.first.keys.include?('instance type')
        warn "CSV is missing instance type"
      end
      # TODO invalid if the last row is blank
      #      a.sort_by do |row|
      #        [
      #          row['series number'] || 'z',
      #          row['subseries number'] || 'z',
      #          row['container 1 number'] || 'z',
      #          row['container 2 number'] || 'z',
      #          row['file title'] || 'z'
      #        ]
      #      end
      a
    end

    def valid?
      # unless Stead.xsd.valid?(ead)
      #   raise Stead::InvalidEad
      # end
      # We are removing this validity check since it needs the xsd which is offline when the federal government closes
      true
    end

    def series?
      if series_found?
        series = true
      end
    end

    def series_found?
      @component_parts.each do |row|
        return false if row['series number'].nil?
      end
    end

    def subseries?
      if subseries_found?
        subseries = true
      end
    end

    def subseries_found?
      @component_parts.each do |row|
        return true if !row['subseries number'].nil?
      end
    end

  end
end

