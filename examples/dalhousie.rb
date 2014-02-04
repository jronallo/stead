module Stead
  class Extra
    attr_accessor :ead, :eadid

    def initialize(ead,eadid)
      @ead = ead
      @eadid = eadid
    end

    def self.run(ead, eadid)
      extra = self.new(ead,eadid)
      extra.add_collection_specific
      ead
    end

    def add_collection_specific
      archdesc_level(ead, 'fonds')
      append_num_to_titleproper(ead, eadid)
      publication_date(ead, eadid)
    end

    def archdesc_level(ead, content)
      archdesc = ead.xpath('//xmlns:archdesc').first
      archdesc['level'] = content
    end

    def append_num_to_titleproper(ead, eadid)
      titleproper = ead.xpath('//xmlns:titleproper').first
      # better_titleproper = titleproper.content.strip.chomp + ' ' + text
      # titleproper.content = better_titleproper
      num = Nokogiri::XML::Node.new('num', ead)
      better_num = eadid.upcase.gsub('_', '.')
      num.content = better_num
      titleproper.add_child(num)

      # now also add to archdesc did
      archdesc_did = ead.xpath('//xmlns:archdesc/xmlns:did').first
      # unittitle = archdesc_did.xpath('xmlns:unittitle').first
      # unittitle.content = better_titleproper
      unitid = archdesc_did.xpath('xmlns:unitid').first
      unitid.content = better_num
    end
    
    def publication_date(ead, eadid)
      time = Time.new
      publicationstmt_date = ead.xpath('//xmlns:publicationstmt/xmlns:date').first
      #publicationstmt_date.content = time.year
    end

  end
end

