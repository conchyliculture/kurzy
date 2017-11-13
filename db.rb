module KurzyDB
    require "logger"
    require "sequel"

    Sequel::Model.plugin(:schema) 

    if not Object.const_defined?(:DB)
        case ENV['RACK_ENV']
        when "test"
            DB = Sequel.sqlite
        else
            DB = Sequel.sqlite 'db/kurzy.sqlite', :loggers => [Logger.new($stderr)]
        end
    end

    class Error < Exception
    end

    class KURL < Sequel::Model(:kurzy)
        set_schema do
            primary_key :id
            String  :short, :unique => true, :empty => false
            String  :url, :unique => false, :empty => false
            Integer :counter, default: 0
            DateTime	:timestamp, default: Sequel::CURRENT_TIMESTAMP
        end
        create_table unless table_exists?
    end

    def KurzyDB.add(url:, short:nil)
        return unless url

        s = short
        unless s
            s = KurzyDB.gen_hash()
        end
        begin
            KURL.insert(url: url, short: s)
        rescue Sequel::UniqueConstraintViolation
            if s == short
                raise KurzyDB::Error.new("The short url #{short} already exists")
            else
                s = KurzyDB.gen_hash()
                KurzyDB.insert(url: url, short: s)
            end
        end
        return s
    end

    def KurzyDB.delete(short:)
        row = KurzyDB.where(short: short)
        row.delete()
        return row.to_hash
    end

    def KurzyDB.gen_hash(length=6)
        temp_hash = [*'a'..'h', 'j', 'k', *'m'..'z', *'A'..'H', *'J'..'N', *'P'..'Z', *'0'..'9', '-', '_'].sample(length).join();
    end

    def KurzyDB.get_url(short:)
        $stderr.puts KURL.where(short: short).sql
        res =  KURL.where(short: short).first()
        if res
            return res[:url]
        else
            return nil
        end
    end
end
