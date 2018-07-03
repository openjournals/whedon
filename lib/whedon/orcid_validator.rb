class String
  def numeric?
    Float(self) != nil rescue false
  end
end

module Whedon
  class OrcidValidator
    attr_reader :orcid

    def initialize(orcid)
      @orcid = orcid.strip
    end

    # Returns true or false
    def validate
      return false unless check_structure
      return false unless check_length
      return false unless check_chars

      if checksum_char == "X" || checksum_char == "x"
        return checksum == 10
      else
        return checksum == checksum_char.to_i
      end
    end

    def packed_orcid
      orcid.gsub('-', '')
    end

    # Returns the last character of the string
    def checksum_char
      packed_orcid[-1]
    end

    def first_11
      packed_orcid.chop
    end

    def check_structure
      groups = orcid.split('-')
      if groups.size == 4
        return true
      else
        warn("ORCID looks malformed") and return false
      end
    end

    def check_length
      if packed_orcid.length == 16
        return true
      else
        warn("ORCID looks to be the wrong length") and return false
      end
    end

    def check_chars
      valid = true
      first_11.each_char do |c|
        if !c.numeric?
          warn("Invalid ORDIC digit (#{c})")
          valid = false
        end
      end

      return valid
    end

    # https://support.orcid.org/knowledgebase/articles/116780-structure-of-the-orcid-identifier
    def checksum
      total = 0
      first_11.each_char do |c|
        total = (total + c.to_i) * 2
      end

      remainder = total % 11
      result = (12 - remainder) % 11

      return result
    end
  end
end
