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
      if eadid.include?('ua')
        # add additional conditions governing use note
        add_ua_userestrict(ead)
        append_to_titleproper(ead, eadid, 'Records')
        archdesc_level(ead, 'subgrp')
      elsif eadid.include?('mc')
        append_to_titleproper(ead, eadid, 'Papers')
        archdesc_level(ead, 'collection')
      end
    end

    def archdesc_level(ead, content)
      archdesc = ead.xpath('//xmlns:archdesc').first
      archdesc['level'] = content
    end

    def add_ua_userestrict(ead)
      first_userestrict = ead.xpath('//xmlns:userestrict').first
      userestrict = Nokogiri::XML::Node.new('userestrict', ead)
      first_userestrict.add_next_sibling(userestrict)
      head = Nokogiri::XML::Node.new('head', ead)
      head.content = 'Confidentiality Notice'
      p = Nokogiri::XML::Node.new('p', ead)
      p.content = <<EOF
          This collection may contain materials with sensitive or confidential
information that is protected under federal or state right to privacy laws and
regulations. Researchers are advised that the disclosure of certain information
pertaining to identifiable living individuals represented in this collection
without the consent of those individuals may have legal ramifications (e.g.,
a cause of action under common law for invasion of privacy may arise if facts
concerning an individual's private life are published that would be deemed
highly offensive to a reasonable person) for which North Carolina State
University assumes no responsibility.
EOF
      userestrict.add_child(head)
      userestrict.add_child(p)
    end

    def append_to_titleproper(ead, eadid, text)
      titleproper = ead.xpath('//xmlns:titleproper').first
      better_titleproper = titleproper.content.strip.chomp + ' ' + text
      titleproper.content = better_titleproper
      num = Nokogiri::XML::Node.new('num', ead)
      better_num = eadid.upcase.gsub('_', '.')
      num.content = better_num
      titleproper.add_child(num)

      # now also add to archdesc did
      archdesc_did = ead.xpath('//xmlns:archdesc/xmlns:did').first
      unittitle = archdesc_did.xpath('xmlns:unittitle').first
      unittitle.content = better_titleproper
      unitid = archdesc_did.xpath('xmlns:unitid').first
      unitid.content = better_num
    end

  end
end

