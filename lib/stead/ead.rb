module Stead
  class EadGenerator
    attr_accessor :csv, :ead, :template, :series, :component_parts

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
      lines = csv.split(/\r\n|\n/)
      100.times do
        lines[0] = lines.first.gsub(',,', ',nothing,')
      end
      csv = lines.join("\n")
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
      end
      @component_parts.each do |cp|
        c = node(file_component_part_name)
        c['level'] = 'file'
        c['audience'] = 'internal' if !cp['internal only'].blank?
        did = node('did')
        c.add_child(did)
        add_did_nodes(cp, did)
        add_containers(cp, did)
        add_scopecontent(cp, did)
        add_accessrestrict(cp, did)
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
        [cp['series number'], cp['series title'], cp['series dates']]
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
      ser.each do |ser_part|
        contents << ser_part unless ser_part.blank?
      end
      item.content = contents.join(', ')
      list.add_child(item)
    end

    # metadata is a hash from the @component_part and c is the actual node
    def add_file_component_part(metadata, c)
      if series?
        current_series = find_current_series(metadata)
        current_series.add_child(c)
      else
        @dsc.add_child(c)
      end
    end

    def find_current_series(cp)
      series_title = cp['series title']
      @ead.xpath("//xmlns:c01/xmlns:did/xmlns:unittitle").each do |node|
        return node.parent.parent if node.content == series_title
      end
    end

    def file_component_part_name
      if series?
        'c02'
      else
        'c01'
      end
    end

    def add_did_nodes(cp, did)
      field_map.each do |header, element|
        if !cp[header].blank?
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
          end
        end
      end
    end

    def add_containers(cp, did)
      ['1', '2', '3'].each do |container_number|
        container_type = cp['container ' + container_number + ' type']
        container_number = cp['container ' + container_number + ' number']
        if !container_type.blank? and !container_number.blank?
          unless valid_container_type?(container_type)
            raise Stead::InvalidContainerType, container_type
          end
          container = node('container')
          container['type'] = container_type
          container['label'] = cp['instance type'] if cp['instance type']
          container.content = container_number
          did.add_child(container)
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

    def add_scopecontent(cp, did)
      unless cp['scopecontent'].blank?
        scopecontent = node('scopecontent')
        p = node('p')
        p.content = cp['scopecontent']
        scopecontent.add_child(p)
        did.add_next_sibling(scopecontent)
      end
    end

    def add_accessrestrict(cp, did)
      unless cp['conditions governing access'].blank?
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
        'extent' => ['physdesc', 'extent'],
        'note1' => ['note', 'p'],
        'note2' => ['note', 'p']
      }
    end

    def csv_to_a
      a = []
      FasterCSV.parse(csv, :headers => :first_row) do |row|
        a << row.to_hash
      end
      if a.first.keys.include?(nil)
        raise Stead::InvalidCsv
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
      unless Stead.xsd.valid?(ead)
        raise Stead::InvalidEad
      end
    end

    def series?
      if series_found?
        series = true
      end
    end

    def series_found?
      @component_parts.each do |row|
        return false if row['series number'].blank?
      end
    end

  end
end

