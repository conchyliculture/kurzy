# Kurzy

## About

Just your simple URL shortener.

Inspired by [lstu.fr](http://lstu.fr), because, srsly, perl?

## Getting Started

```
apt install ruby-slim ruby-sequel ruby-sinatra
git clone https://github.com/conchyliculture/kurzy
cd kurzy
```
change the `$adminpwd` value to something sensible.
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

BOOM! Now just type `k<TAB>t<ENTER>` and you're on the best page of the world!

## Logging in

You can log in by providing the password. If you open the list view, you can now delete links!

## Security and Privacy

### Security

Nope.

### Privacy

Lol.
