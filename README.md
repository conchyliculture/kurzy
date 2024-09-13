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

## Serverization

I use [puma](https://puma.io/) in [firejail](https://firejail.wordpress.com/).

One possible `firejail.profile` for this is:

```
read-write /var/www/kurzy
noblacklist /var/www/kurzy
blacklist /var/www/*
include /etc/firejail/default.profile
```

You can try to write the following in `/etc/systemd/system/kurzy.service`, considering that you have put the files in `/var/www/kurzy`:

```
[Unit]
Description=Firejailed kurzy
After=network.target

[Service]
User=puma
ExecStart=/usr/bin/firejail --quiet --profile=/var/www/kurzy/firejail.profile --name=app_kurzy -- /usr/bin/puma --quiet -C /etc/puma.conf.d/kurzy.conf
```

And then create `/var/www/kurzy/puma` folder, owned by the `puma` user, where logs & stuff will be dropped.

Finally, a puma config file can be added to `/etc/puma.conf.d/kurzy.conf`

```
directory '/var/www/kurzy'
environment 'production'
pidfile '/var/www/kurzy/puma/puma.pid'
state_path '/var/www/kurzy/puma/puma.state'
stdout_redirect '/var/www/kurzy/puma/stdout.log', '/var/www/kurzy/puma/stderr.log', 'true'
bind 'tcp://10.11.0.40:9290'
tag 'Kurzy'
```


## Security and Privacy

### Security

Not really. Trying my best though!

### Privacy

Lol.

### Testing

Some!

Just run `ruby test/tests.rb` after you've installed `ruby-rack-test`
