# Kurzy

## About

Just your simple URL shortener.

Inspired by [lstu.fr](http://lstu.fr), because, srsly, perl?

## Getting Started

```
apt install ruby-slim ruby-sequel ruby-sqlite3 ruby-sinatra puma
git clone https://github.com/conchyliculture/kurzy
cd kurzy
```

```
cp config.json.template config.json
```

Then edit `config.json` to your needs. It's important you change `domain` (for cookies management) and `admin_password` (for obvious reasons).

The `private_inserts` key changes whether you want the public to be able to add short links, or if only the admin can.


```
ruby kurzy.rb
```

and navigate to http://localhost:4567 .

![Screenshot](doc/sc1.png?raw=true "Kurzy")


Add new links there, for example shortlink `t` for `https://twitter.com/africabytotobot`.
Now you can navigate to `http://localhost:4567/t` to be redirected to `https://twitter.com/africabytotobot`


## Web browser magic

### Chrome

Go to `chrome://settings/searchEngines`, click Add to create a new Search engine:
  * Name: Kurzy
  * Keyword: k
  * URL : http://localhost:4567/%s

BOOM! Now just type `k<TAB>t<ENTER>` and you're on the best website in the world!

## Logging in

You can log in by providing the password. This gives you access to the list view, where you  can now delete links!

## Security and Privacy

### Security

Not really. Trying my best though!

### Privacy

Lol.

### Testing

Some!

Just run `ruby test/tests.rb` after you've installed `ruby-rack-test`
