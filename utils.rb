class KurzyError < Exception
end

module KurzyUtils

    def KurzyUtils.gen_hash(length=6)
        [*'a'..'h', 'j', 'k', *'m'..'z', *'A'..'H', *'J'..'N', *'P'..'Z', *'0'..'9', '-', '_'].sample(length).join()
    end

    def KurzyUtils.remove_bad_urlchar(s)
        s = '' unless s
        return s.gsub(/[^-A-Za-z0-9+&@#\/%?=~_|!:,.;\(\)]/, "")
    end

    def self.r(s)
        KurzyUtils.remove_bad_urlchar(s)
    end

    def KurzyUtils.url_filter(url)
        clean_url = r("")
        u = URI.parse(url)
        clean_url = u.scheme + "://" + r(u.host)
        clean_url += [80, 443, nil].include?(u.port) ? '' : ":#{u.port}"
        clean_url += r(u.path)
        clean_url += "?#{r(u.query)}" if u.query
        clean_url += ('#' + r(u.fragment)) if u.fragment
        return clean_url
    end

    def KurzyUtils.remove_bad_shortchar(s)
        return s.gsub(/[^-A-Za-z0-9+\/%=~_|!:,.\(\)]/, "")
    end

    def KurzyUtils.short_filter(short)
        return nil unless short
        return nil if short.length > 20
        return KurzyUtils.remove_bad_urlchar(short)
    end
end
