module KurzyDB
    require "sequel"
    require_relative "utils.rb"

    if not Object.const_defined?(:DB)
        case ENV['RACK_ENV']
        when "test"
            # Make a DB in memory when testing
            DB = Sequel.sqlite
        else
            DB = Sequel.sqlite 'db/kurzy.sqlite'
        end
    end
    unless DB.table_exists?(:kurzy)
        DB.create_table :kurzy do
            primary_key :id
            String  :short, :unique => true, :empty => false
            String  :url, :unique => false, :empty => false
            Integer :counter, default: 0
            DateTime	:timestamp, default: Sequel::CURRENT_TIMESTAMP
            Boolean :private, default: 1
        end
    end

    class Error < Exception
    end

    class KURL < Sequel::Model(:kurzy)
    end

    def KurzyDB.add(url:, short:"", priv:true)
        return unless url

        s = short || ""

        begin
            KURL.insert(url: url, short: s, private: priv)
        rescue Sequel::UniqueConstraintViolation
            if s == short
                raise KurzyDB::Error.new("The short url #{short} already exists")
            else
                s = KurzyUtils.gen_hash()
                KurzyDB.insert(url: url, short: s, private: priv)
            end
        end
        return s
    end

    def KurzyDB.delete(short:)
        row = KURL.where(short: short).first
        if row
            row.delete()
            return row.to_hash
        else
            raise KurzyDB::Error.new("The short url #{short} doesn't exist")
        end
    end

    def KurzyDB.get_url(short:)
        res =  KURL.where(short: short).first()
        if res
            KURL.where(id: res[:id]).update(counter: res[:counter]+1)
            return res[:url]
        end
        return nil
    end

    def KurzyDB.list(max:nil, priv: false)
        rows = priv ? KURL.all :  KURL.where(private: false)
        return rows.map{ |row| row.to_hash }
    end

    def KurzyDB.truncate()
        KURL.truncate()
    end
end

