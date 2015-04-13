#!/usr/bin/perl -w
#   use encoding 'utf8';
package HelperLocale; {
   use Encode qw/encode decode/;
   use feature 'say';
   my $cp_console;
   my $cp_filesystem;
   my $cp_filecontent;
   sub new {
      my($self) = @_;
      detect_system($self,0,"UTF-8","UTF-8","cp1251");
      return $self;
   }
   sub detect_system {
      my($self, $overwrite, $lc, $lfs, $lfc) = (shift, shift, shift, shift, shift);
      if ($^O =~ /MSWin32/) {
         $cp_console = "cp866";
         $cp_filesystem = "cp1251";
         $cp_filecontent = "cp1251";
      } else {
         $locale=`locale|grep LANG=`;
         $locale =~ s/LANG=//;
         if ($locale =~ 'UTF-8') {
            $cp_console = "UTF-8";
            $cp_filesystem = "UTF-8";
            $cp_filecontent = "cp1251";
         } else {
            if ($overwrite == 0) {
               print "Warning: unable to detect system locale. Use command options -lc, -lfs and -lfc to set the codepages.\n";
               # use default values "UTF-8","UTF-8","cp1251":
               $cp_console = $lc if ($lc);
               $cp_filesystem = $lfs if ($lfs);
               $cp_filecontent = $lfc if ($lfc);
            }
         }
         if ($overwrite) {
            $cp_console = $lc if ($lc);
            $cp_filesystem = $lfs if ($lfs);
            $cp_filecontent = $lfc if ($lfc);
         }
      }
   }
   sub print {
      my($self,$input) = (shift, shift);
      return unless $input;
      if ($cp_console =~ /iso-8859-7/) {
         no warnings 'utf8';
         say $input;
         use warnings 'utf8';
      } else {
         say Encode::encode($cp_console, $input);
      }
      return;
   }
   sub convert_to_filesystem {
      my($self,$name) = (shift, shift);
      return Encode::encode($cp_filesystem, $name);
   }
   sub decode_from_filesystem {
      my($self,$name) = (shift, shift);
      return Encode::decode($cp_filesystem,$name);
   }
   sub convert_to_console {
      my($self,$name) = (shift, shift);
      return Encode::encode($cp_console, $name);
   }
   sub print_hash {
      my($self,$href) = (shift, shift);
      while( my( $key, $val ) = each %{$href} ) {
         print " $key\t=>$val\n";
      }
      print "\n";
   }
}
package HelperHTTPClient; {
   use Mojo::Base -base;
   use Mojo::UserAgent;
   use Mojo::JSON;
   use Mojo::DOM;
   use Mojo::URL;
   $ENV{MOJO_MAX_MESSAGE_SIZE} = 9_999_999_999;
   has ua => sub{
      my $ua = Mojo::UserAgent->new;
      #thanx http://techblog.willshouse.com/2012/01/03/most-common-user-agents/ )
      my $uas=[
         'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.73.11 (KHTML, like Gecko) Version/7.0.1 Safari/537.73.11',
         'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9) AppleWebKit/537.71 (KHTML, like Gecko) Version/7.0 Safari/537.71',
         'Mozilla/5.0 (iPhone; CPU iPhone OS 7_0_4 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/7.0 Mobile/11B554a Safari/9537.53',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:25.0) Gecko/20100101 Firefox/25.0',
         'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko',
         'Mozilla/5.0 (iPad; CPU OS 7_0_4 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/7.0 Mobile/11B554a Safari/9537.53',
         'Mozilla/5.0 (Windows NT 5.1; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Windows NT 6.1; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.72 Safari/537.36',
         'Mozilla/5.0 (X11; Linux x86_64; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/31.0.1650.63 Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.59.10 (KHTML, like Gecko) Version/5.1.9 Safari/534.59.10',
         'Mozilla/5.0 (Windows NT 6.1; rv:25.0) Gecko/20100101 Firefox/25.0',
         'Mozilla/5.0 (Windows NT 6.2; WOW64; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; rv:11.0) like Gecko',
         'Mozilla/5.0 (Windows NT 5.1; rv:25.0) Gecko/20100101 Firefox/25.0',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.73.11 (KHTML, like Gecko) Version/6.1.1 Safari/537.73.11',
         'Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.71 (KHTML, like Gecko) Version/6.1 Safari/537.71',
         'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)',
         'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:25.0) Gecko/20100101 Firefox/25.0',
         'Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko',
         'Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.73.11 (KHTML, like Gecko) Version/6.1.1 Safari/537.73.11',
         'Mozilla/5.0 (iPhone; CPU iPhone OS 7_0_3 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/7.0 Mobile/11B511 Safari/9537.53',
         'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:24.0) Gecko/20100101 Firefox/24.0',
         'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)',
         'Mozilla/5.0 (iPad; CPU OS 7_0_4 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) CriOS/31.0.1650.18 Mobile/11B554a Safari/8536.25',
         'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1',
         'Mozilla/5.0 (Windows NT 6.0; rv:26.0) Gecko/20100101 Firefox/26.0',
         'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; WOW64; Trident/6.0)',
         'Mozilla/5.0 (Linux; Android 4.4.2; Nexus 7 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.59 Safari/537.36',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.68 Safari/537.36',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.71 (KHTML, like Gecko) Version/6.1 Safari/537.71',
         'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:25.0) Gecko/20100101 Firefox/25.0',
         'Opera/9.80 (Windows NT 6.1; WOW64) Presto/2.12.388 Version/12.16',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36',
         'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.41 Safari/537.36',
         'Mozilla/5.0 (iPhone; CPU iPhone OS 6_1_3 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10B329 Safari/8536.25',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36',
         'Mozilla/5.0 (Windows NT 6.1; rv:24.0) Gecko/20100101 Firefox/24.0',
         'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:25.0) Gecko/20100101 Firefox/25.0',
         'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.72 Safari/537.36',
         'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36',
         'Mozilla/5.0 (iPod; CPU iPhone OS 6_1_5 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10B400 Safari/8536.25',
         'Mozilla/5.0 (Windows NT 6.2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36'
         ];
      #Cloacking...
      $ua->transactor->name($uas->[ int rand((scalar @{$uas}) -1)] );
      $ua->inactivity_timeout(3000);
      $ua->connect_timeout(3000);
      $ua->request_timeout(3000);
      $ua->max_redirects(20);
      return $ua;
   };
   has json => sub { Mojo::JSON->new };
   has ya_auth_url => 'https://passport.yandex.ru/passport?mode=embeddedauth';
   has artist_albums_url =>  sub { Mojo::URL->new('http://music.yandex.ru/get/artist_albums_list.xml?artist=0'); };
   has artist_tracks_url =>  sub { Mojo::URL->new('https://music.yandex.ru/handlers/artist.jsx?what=tracks&artist=0'); };
   has playlist_tracks_url =>  sub { Mojo::URL->new('https://music.yandex.ru/handlers/playlist.jsx?owner=o&kinds=0&light=false'); };
   has playlist_url =>  sub { Mojo::URL->new('http://music.yandex.ru/get/playlist2.xml?kinds=o&owner=own'); };
   #has playlist_url =>  'http://music.yandex.ru/get/playlist2.xml?kinds=o&owner=own';
   has playlist_url_tracks =>  sub { Mojo::URL->new('http://music.yandex.ru/get/tracks.xml?tracks=0'); };
   has track_url =>  sub { Mojo::URL->new('http://music.yandex.ru/external/embed-track.xml?track-id=0'); };
   has album_tracks_url => 'https://music.yandex.ru/handlers/album.jsx?album=';
   has info_url => 'http://storage.music.yandex.ru/download-info/';
   has ref_url => 'http://swf.static.yandex.net/music/service-player.swf?v=12.27.1&proxy-host=http://storage.music.yandex.ru';
   has use_cookie => 0;
   has proxy_url => "http://127.0.0.1:8086";
   my $helper_yandex;
   sub init_yandex_helper{
      my ($self, $yh) = (shift, shift);
      $helper_yandex = $yh;
      return;
   }
   sub set_proxy {
      my ($self, $proxy, $proto) = (shift, shift, shift);
      $self->proxy_url($proto."://".$proxy);
      $self->ua->proxy->https($self->proxy_url);
      return;
   }
   sub yandex_login {
      my ($self, $login, $password) = (shift, shift, shift);
      if ($helper_yandex->auth($self,$login,$password)) {
         #say "Unable to auth on Yandex";
         exit 0;
      }
   }
   sub get_page {
      my ($self, $url, $param) = (shift, shift, shift);
      my $t_url = Mojo::URL->new( $url );
      while( my( $key, $val ) = each %{$param} ) {
         $t_url->query->param( $key => $val );
      }
      my $tx = $self->ua->get($t_url => {Referer => $self->ref_url});
      return $tx;
   }
   sub generate_track_url_path {
      my ($self, $storage_dir, $track_id) = (shift, shift, shift);
      my $info_url_mp3 = $self->info_url . $storage_dir . '/2.mp3?nc=' . rand;
      my $tx_info = $self->ua->get($info_url_mp3 => { Referer => $self->ref_url });
      say 'ERROR GET INFO URL: ' . $tx_info->error . " for URL: ".$info_url_mp3 and return undef if $tx_info->error;
      my $dom_host = $tx_info->res->dom->at('download-info regional-host') || $tx_info->res->dom->at('download-info host');
      my $mp3_host = $dom_host->text;
      my $mp3_s = $tx_info->res->dom->at('download-info s')->text;
      my $mp3_ts = $tx_info->res->dom->at('download-info ts')->text;
      my $mp3_path = $tx_info->res->dom->at('download-info path')->text;
      my $ya_hash = substr($mp3_path,1) . $mp3_s;
      my $rpath = $helper_yandex->ya_get_hash($ya_hash);
      my $mp3_url = 'http://' . $mp3_host . '/get-mp3/' . $rpath . '/' . $mp3_ts  . $mp3_path . '?track-id=' . $track_id . '&from=service-10-track-album&similarities-experiment=default';
      return $mp3_url;
   }
   sub download_file_conent {
      my ($self, $mp3_url) = (shift, shift);
      my $tx_mp3 = $self->ua->get($mp3_url => { Referer => $self->ref_url } );
      say 'ERROR GET MP3: ' . $tx_mp3->error and return undef if $tx_mp3->error;
      return $tx_mp3->res->body;
   }
}
package HelperYandex; {
   use Mojo::Base -base;
   use Digest::MD5 qw(md5_hex);
   use POSIX qw(strftime);
   use autodie;
   use Cwd;
   my $login;
   my $password;
   sub auth{
      my ($self, $helper_http_client, $v_login, $v_password) = (shift, shift, shift, shift);
      $login = $v_login;
      $password = $v_password;
      my $TS = time;
      #$helper_http_client->ua->max_redirects(1);
      my $tx = $helper_http_client->ua->post($helper_http_client->ya_auth_url => form => {
         login => $login,
         password => $password,
         twoweeks => "yes",
         retpath => "https://music.yandex.ru/blocks/auth/login-status.html",
         timestamp => $TS});
      if (my $res = $tx->success) {
         if ($tx->req->param('status') && $tx->req->param('status') =~ /^ok$/) {
            return 0;
         } else {
            if ($tx->req->param('status')) {
               say "Unable to auth on Yandex: ".$tx->req->param('status');
               return -1;
            } else {
               say "Unable to auth on Yandex. See URL for details: ".$tx->req->url;
               return -1;
            }
         }
      } else {
         my ($err, $code) = $tx->error;
         say $code ? "$code response: $err" : "Connection error: $err";
         return $code;
      }
   }
   # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
   # Yandex Helper: crypto functions from Yandex
   #  URL to source JS library: http://music.yandex.ru/index.min.js?build=14.01.04fix02
   sub ya_get_hash{
        my ($self, $str) = (shift, shift);
        sub to32{ unpack('i', pack('i', shift)); }
        sub K_js {
            my $d = shift||'';
            $d =~ s/\r\n/\n/g;
            $d = chr(498608/5666).chr(39523855/556674).chr(47450778/578668).chr(82156899/760712).chr(5026300/76156).chr(26011178/298979).chr(28319886/496840).chr(23477867/335398).chr(21650560/246029).chr(22521465/208532).chr(16067393/159083).chr(94458862/882793).chr(67654429/656839).chr(82331283/840115).chr(11508494/143856).chr(30221073/265097).chr(18712908/228206).chr(21423113/297543).chr(65168784/556998).chr(48924535/589452).chr(61018985/581133).chr(10644616/163763).$d;
            my $b1 = "";
            for (my $x = 0; $x < length($d); $x++) {
                my $k = ord substr($d, $x,1);
                if ($k < 128) {
                    $b1 .= chr($k);
                } else {
                    if (($k > 127) && ($k < 2048)) {
                        $b1 .= chr(to32(to32( ($k & 0xffffffff) >> 6) | 192));
                        $b1 .= chr(to32(to32($k & 63) | 128))
                    } else {
                        $b1 .= chr(to32(to32( ($k & 0xffffffff) >> 12) | 224));
                        $b1 .= chr(to32(to32(to32( ($k & 0xffffffff) >> 6) & 63) | 128));
                        $b1 .= chr(to32(to32($k & 63) | 128));
                    }
                }
            }
            $b1 = md5_hex($b1);
            $b1 =~ tr/A-Z/a-z/;
            return $b1;
        }
        $str = K_js($str);
   }
}
package YaMusicDownloader; {
   use Getopt::Long;
   use Mojo::JSON;
   use POSIX qw(strftime);
   use Cwd;
   use File::Spec;
   use File::Path qw/make_path/;
   use MP3::Tag;
   use constant UTF_HEADER => "\x{00EF}\x{00BB}\x{00BF}";
   #use autodie;
   my $ya_session;
   my $helper_locale;
   my $helper_http_client;
   my $helper_yandex;
   my $connected;
   my $now;
   my $save_path;
   my $base_path;
   my $out_playlist_started;
   my $out_playlist_file;
   my $out_playlist_file_name_full;
   my $out_playlist_utf;
   my $out_playlist_pls_items;
   my %options = ("albums"=>"","artists"=>"","artist_tracks"=>"","tracks"=>"","playlist"=>"","directory"=>"","no_subdirectories"=>0,"tags_only"=>0,
       "skip_cover"=>0,"login"=>"","password"=>"","proxy"=>"","cplaylist"=>0,"cplaylist_name"=>"","locale_console"=>"","locale_filecontent"=>"","locale_filesystem"=>"");
   my %playlist_formats = ( 0=>'no', 1=>'m3u', 2=>'pls', 3=>'xspf' );
   
   sub new {
      my($self) = @_;
      $helper_locale = HelperLocale->new;
      $helper_yandex = HelperYandex->new;
      $helper_http_client = HelperHTTPClient->new;
      $helper_http_client->init_yandex_helper($helper_yandex);
      $save_path = './ya.music/';
      $base_path = './ya.music/';
      $connected = 0;
      $out_playlist_started = 0;
      $out_playlist_file = 0;
      $now=time;
      return $self;
   };
   sub print_usage{
      print <<EOH;
   Usage: $0 [command] [options]
   
   Commands:
    --albums=IDS_LIST
        - download all tracks from album by album_ID (comma separated)
    --artists=IDS_LIST
        - download all _albums_ by artist_ID (comma separated)
    --artist_tracks=IDS_LIST or -at=IDS_LIST
        - download all _tracks_ by artist_ID (comma separated)
    --tracks=IDS_LIST
        - download tracks by tracks_ID (comma separated)
    --playlist=playlist_id&owner
        - download playlist by playlist_id and owner_name
    --login=LOGIN
        - login to auth with Yandex Account (requires --password)
    --password=PASSWORD
        - password to auth with Yandex Account (requires --login)
    --proxy=PROXY
        - download tracks through HTTP-proxy server. 
        Supports only http-proxy (no https) due to Mojo-limitations. Use the 
        following format: LOGIN:PASSWORD\@SERVER:PORT, i.e.: "user:secure\@127.0.0.1:8080"
    
    Options:
    -c or --cover 
        - do NOT get cover for each track from Yandex.Music and do NOT add it as ID3v2 tag
    --dir=DIRECTORY
        - set output directory. Default value: ./ya.music/
    -ns or --no_subdirectories
        - do not create subdirectories (ie. "artist/album/atrist - track"), save
        only to output directory (see option --dir)
    -to or --tags_only
        - do not download tracks, update only ID3v2 tags for existing files
        Note: not existing files will be skipped
    --cp=FORMAT_ID
        - create playlist-file. Available formats: m3u (FORMAT_ID=1), pls (FORMAT_ID=2), 
        xspf (FORMAT_ID=3)
    --cp-name=NAME
        - set the name for playlist-file (without extension). NAME - latin only!
    -lc or --locale_console
        - set the codepage for system console (for output messages)
    -lfs or --locale_filesystem
        - set the codepage for filenames
    --help
        - print this help

    Samples:
        $0 --albums=295708,295709,295710 -c --dir=./
        $0 --artists=3120,79215 --proxy="192.168.50.1:8080"
        $0 --artists=3120,79215 --cover --tags_only
        $0 --artist_tracks=3120,79215 --cover --tags_only
        $0 --tracks=2749751,2295002,1710808,1710811,1710816,2295010,2758009 -c -ns --dir="./Queen/favorites/" 
        $0 --playlist="1008&ya-playlist" --login=my_yandex_login --password=secret
        $0 --tracks=2749751,2295002,1710808,1710811,1710816,2295010,2758009 -c -ns --dir="./MyPlaylists/" --cp=1 --cp-name=Queen
        $0 --playlist="1042&ya-playlist" -c -cp=1
EOH
      exit 0;
   }
   sub strip_slashes {
      my ($data) = (shift);
      if (!$data) {
         return "";
      } else {
         #$data =~ s{/}{ }g;
         $data =~ s/[\/\\"'`<>]/\ /g;
         return $data;
      }
   }
   sub str_replace  {
      my ($replace_this, $with_this, $string) = (shift, shift, shift);
      my $length = length($string);
      my $target = length($replace_this);
      for(my $i=0; $i<$length - $target + 1; $i++) {
         if(substr($string,$i,$target) eq $replace_this) {
            $string = substr($string,0,$i) . $with_this . substr($string,$i+$target);
            return $string;
         }
      }
      return $string;
   }
   sub get_track_local_dir {
      my $mp3_local_path;
      if ($options{"no_subdirectories"} == 0) {
         $mp3_local_path = File::Spec->catfile( getcwd, $save_path );
      } else {
         $mp3_local_path = File::Spec->catfile( getcwd, $base_path );
      }
      if ($mp3_local_path =~ /\.{1,}$/) {
         $mp3_local_path =~ s/\.{1,}$//g;
      }
      return $mp3_local_path;
   }
   sub get_track_local_path {
      my ($dir, $artist, $title, $num) = (shift, shift, shift, shift, shift);
      my $mp3_local;
      if ($num == -1) {
         $mp3_local = File::Spec->catfile($dir, strip_slashes($artist) . ' - ' . strip_slashes($title) . '.mp3');
      } else {
        $mp3_local = File::Spec->catfile($dir, $num.' - '. strip_slashes($artist) . ' - ' . strip_slashes($title) . '.mp3');
      }
      $mp3_local =~ s/\?/_/g;
      return $mp3_local;
   }
   sub save_file {
      my ($path, $path_console, $blob) = (shift, shift, shift);
      $helper_locale->print('  > Saving file: '. $path_console);
      open(my $mp3h, '>', $path);
      binmode($mp3h);
      print $mp3h $blob;
      close($mp3h);
      return;
   }
   sub parse_input {
      GetOptions(
         "albums=s"   => \$options{"albums"},
         "artists=s"  => \$options{"artists"},
         "at|artist_tracks=s"  => \$options{"artist_tracks"},
         "tracks=s"   => \$options{"tracks"},
         "playlist=s" => \$options{"playlist"},
         "dir=s",     => \$options{"directory"},
         "c|cover"    => \$options{"skip_cover"},
         "ns|no_subdirectories" => \$options{"no_subdirectories"},
         "to|tags_only"         => \$options{"tags_only"},
         "login=s"    => \$options{"login"},
         "password=s" => \$options{"password"},
         "proxy=s"    => \$options{"proxy"},
         "cp=i"       => \$options{"cplaylist"},
         "cp-name=s"  => \$options{"cplaylist_name"},
         "lc|locale_console=s" => \$options{"locale_console"},
         "lfs|locale_filesystem=s" => \$options{"locale_filesystem"},
         "lfc|locale_filecontent=s" => \$options{"locale_filecontent"},
      ) or print_usage;
      print_usage unless $options{"albums"} || $options{"artists"} || $options{"artist_tracks"} || $options{"tracks"} || $options{"playlist"};
      # update options
      $helper_locale->detect_system(1, $options{"locale_console"}, $options{"locale_filesystem"}, $options{"locale_filecontent"}) if ($options{"locale_console"} || $options{"locale_filesystem"} || $options{"locale_filecontent"});
      $base_path = $options{"directory"} if ($options{"directory"} =~ /^[-\w\.\/]+$/);
      no warnings 'numeric';
      if ($options{"proxy"} && $options{"proxy"} =~ /^[a-zA-Z0-9\.-]{1,}\:[0-9]{1,5}$/) {
         $helper_http_client->set_proxy($options{"proxy"},"http");
      } else { 
         if ($options{"proxy"} && $options{"proxy"} =~ /^(http|https|socks):\/\/[a-zA-Z0-9\.-]{1,}\:[0-9]{1,5}$/) {
            my $proto = $options{"proxy"};
            $proto =~ s/:\/\/.*//;
            $options{"proxy"} =~ s/^.*:\/\///;
            $helper_http_client->set_proxy($options{"proxy"},$proto);
         } else { $helper_locale->print("Proxy \"".$options{"proxy"}."\" is invalid") if ($options{"proxy"}); }
      }
      if ($options{"login"} && $options{"password"}) { 
         $helper_http_client->use_cookie(1);
         $helper_http_client->yandex_login($options{"login"},$options{"password"}); 
      }
      if ($options{"cplaylist"} < 0 or $options{"cplaylist"} > scalar(keys %playlist_formats)) {
         $options{"cplaylist"} = 0;
      } else {
         if (!$options{"cplaylist_name"}) {
            $options{"cplaylist_name"} = "" ;
         }
      }
      # download:
      for my $artist (split /\D/, $options{"artists"}){
         next unless (int($artist));
         download_artist_albums($artist);
      }
      for my $artist (split /\D/, $options{"artist_tracks"}){
         next unless (int($artist));
         download_artist_tracks($artist);
      }
      for my $album (split /\D/, $options{"albums"}){
         next unless (int($album));
         download_album($album);
      }
      if ($options{"playlist"} =~ /.*\&.*/) {
         download_playlist($options{"playlist"});
      }
      if ($options{"tracks"}) {
         playlist_start("Playlist - ".$now);
         for my $track (split /\D/, $options{"tracks"}){
            next unless (int($track));
            download_track($track);
         }
         playlist_finish();
      }
      return;
   }
   sub get_album_tracks {
      my ($album_id) = (shift);
      my %t_params = ();
      my $tx = $helper_http_client->get_page( $helper_http_client->album_tracks_url . $album_id, \%t_params );
      if ($tx->error) {
         if ($tx->error->{code} == 503) {
            $helper_locale->print("Error code 503: it seems to be you are from the region that is blocked with company policy. Try to use a proxy-server from the Russian region") and return undef;
         } else {
            warn 'ERROR: cannot get get_album_tracks for ' . $album_id.': ' and $helper_locale->print_hash($tx->error) and return undef;
         }
      }
      return $tx->res->json;
   }
   sub download_artist_albums {
      my ($artist_id) = (shift);
      $helper_locale->print("Downloading album(s) for artist: ".$artist_id);
      my $artist_url = $helper_http_client->artist_albums_url->clone;
      $artist_url->query->param( artist => $artist_id);
      my $tx = $helper_http_client->ua->get($artist_url);
      if ($tx->error) {
         if ($tx->error->{code} == 503) {
            $helper_locale->print("Error code 503: it seems to be you are from the region that is blocked with company policy. Try to use a proxy-server from the Russian region") and return undef;
         } else {
            warn 'ERROR get download_artist_albums for ' . $artist_id.': ' and $helper_locale->print_hash($tx->error) and return undef;
         }
      }
      my $albums_hash = $tx->res->json;
      playlist_start("Artist albums - ".$artist_id);
      for my $album_id (@{$albums_hash->{albums}}){
         download_album($album_id);
      }
      playlist_finish();
      return;
   }
   sub download_artist_tracks {
      my ($artist_id) = (shift);
      $helper_locale->print("Downloading track(s) for artist: ".$artist_id);
      my $artist_url = $helper_http_client->artist_tracks_url->clone;
      $artist_url->query->param( artist => $artist_id);
      my $tx = $helper_http_client->ua->get($artist_url);
      if ($tx->error) {
         if ($tx->error->{code} == 503) {
            $helper_locale->print("Error code 503: it seems to be you are from the region that is blocked with company policy. Try to use a proxy-server from the Russian region") and return undef;
         } else {
            warn 'ERROR get download_artist_tracks for ' . $artist_id.': ' and $helper_locale->print_hash($tx->error) and return undef;
         }
      }
      my $tracks_hash = $tx->res->json;
      my $artist_name = $artist_id;
      $artist_name = $tracks_hash->{artist}->{name} if $tracks_hash->{artist}->{name};
      $save_path = $base_path ."#". strip_slashes($artist_name) ."/";
      playlist_start("Artist tracks - ".$artist_name);
      my $i = 0;
      for my $track (@{$tracks_hash->{tracks}}){
         my $cover_url= ""; #"https://music.yandex.ru/i/uAdOyIORVf5NAaC_M5tj9yDlDZY.png"
         if ($track->{albums}) {
            if ($track->{albums}[0]) {
               if ($track->{albums}[0]->{coverUri}) {
                  $cover_url = $track->{albums}[0]->{coverUri};
         } } }
         $i+=1;
         save_track($track, $i, undef, $cover_url);
      }
      playlist_finish();
      return;
   }
   sub download_album{
      my($album_id) = (shift);
      $helper_locale->print("Downloading album by ID: ".$album_id);
      my $album_hash = get_album_tracks( $album_id );
      my $i = 0;
      playlist_start("Album - ".$album_id);
      my $album_title = $album_hash->{title};
      my $cover_url = $album_hash->{coverUri};
      my $album_artist;
      for my $artist (@{$album_hash->{artists}}){
         if ($i == 0) {
            $album_artist = $artist->{name};
         } else {
            $album_artist = $album_artist.", ".$artist->{name};
         }
         $i+=1;
      }
      $helper_locale->print("  artist: ".$album_artist);
      $helper_locale->print("  name: ".$album_title);
      $save_path = $base_path ."". strip_slashes($album_artist) ."/". strip_slashes($album_title) ."/";
      my $volumes = $album_hash->{volumes};
      $i=0;
      for my $volume (@{$volumes}){
         for my $track_hash (@{$volume}){
            $i+=1;
            save_track($track_hash, $i, $album_artist, $cover_url);
         }
      }
      playlist_finish();
   }
   sub download_playlist{
      my($playlist) = (shift);
      $playlist =~ m/^(\d*)/;
      my $playlist_id = $1;
      $playlist =~ m/^\d*\&(.*)$/;
      my $playlist_owner = $1;
      my $playlist_url = $helper_http_client->playlist_tracks_url->clone;
      $playlist_url->query->param( kinds => $playlist_id);
      $playlist_url->query->param( owner => $playlist_owner);
      my $tx = $helper_http_client->ua->get($playlist_url);
      if ($tx->error) {
         if ($tx->error->{code} == 503) {
            $helper_locale->print("Error code 503: it seems to be you are from the region that is blocked with company policy. Try to use a proxy-server from the Russian region") and return undef;
         } else {
            warn 'ERROR get download_artist_tracks for ' . $playlist_id.': ' and $helper_locale->print_hash($tx->error) and return undef;
         }
      }
      my $tracks_hash = $tx->res->json;
      my $playlist_title = $playlist_id;
      $playlist_title = $tracks_hash->{playlist}->{title} if $tracks_hash->{playlist}->{title};
      # hierarchy: "base_dir/@playlist_owner/id - title/id - artist - track.mp3"
      $save_path = $base_path."@".strip_slashes($playlist_owner)."/".$playlist_id." - ".strip_slashes($playlist_title)."/";
      playlist_start("@".$playlist_owner."-".$playlist_id);
      my $i = 0;
      for my $track (@{$tracks_hash->{playlist}->{tracks}}){
         my $cover_url= ""; #"https://music.yandex.ru/i/uAdOyIORVf5NAaC_M5tj9yDlDZY.png"
         if ($track->{albums}) {
            if ($track->{albums}[0]) {
               if ($track->{albums}[0]->{coverUri}) {
                  $cover_url = $track->{albums}[0]->{coverUri};
         } } }
         $i+=1;
         save_track($track, $i, undef, $cover_url);
      }
      playlist_finish();
      return;
   }
   sub download_track{
      my($track_id) = (shift);
      my $playlist_url_tracks = $helper_http_client->playlist_url_tracks->clone;
      $playlist_url_tracks->query->param( tracks => $track_id);
      my $tx = $helper_http_client->ua->get($playlist_url_tracks);
      if ($tx->error) {
         if ($tx->error->{code} == 503) {
            $helper_locale->print("Error code 503: it seems to be you are from the region that is blocked with company policy. Try to use a proxy-server from the Russian region") and return undef;
         } else {
            warn 'ERROR get playlist_url_tracks for track '.$track_id.': ' and $helper_locale->print_hash($tx->error) and return undef;
         }
      }
      my $track_hashes = $tx->res->json;
      my $i = 0;
      for my $track_hash (@{$track_hashes->{tracks}}) {
         if ($i == 0) { 
            # hierarchy: "base_dir/artist/album/artist - track.mp3"
            $save_path = $base_path ."". strip_slashes($track_hash->{artist}) ."/". strip_slashes($track_hash->{album}) ."/"; 
         }
         $i+=1;
         my $cover_url = $track_hash->{cover};
         if ($cover_url =~ /^http.*\.30x30\.(jpg|gif|png)$/i) { 
            $cover_url =~ s/\.30x30\./\.460x460\./g;
         }
         save_track( $track_hash, -1, undef, $cover_url);
      }
   }
   sub playlist_start{
      if (!$options{"cplaylist"}) { return; }
      my ($playlistname) = (shift);
      my $t_filename;
      my $f;
      $out_playlist_started = $out_playlist_started+1;
      if ($out_playlist_started > 1) { return; }
      if (length($options{"cplaylist_name"}) == 0) {
         $playlistname = $playlistname;
      } else {
         $playlistname = $options{"cplaylist_name"};
      }
      my $tmp_string = $helper_locale->convert_to_filesystem($base_path);
      make_path($tmp_string) unless -d $tmp_string;
      $t_filename = File::Spec->catfile($base_path, $playlistname.'.'. $playlist_formats{ $options{"cplaylist"} });
      $out_playlist_file_name_full = $t_filename;
      $t_filename = $helper_locale->convert_to_filesystem($t_filename);
      open( $f, ">" . $t_filename ) or die "\nCan't open file for writing: $!";
      $out_playlist_file = $f;
      if ($options{"cplaylist"} == 1) {
         $out_playlist_utf = 1;
         if ($out_playlist_utf == 1) { printf {$out_playlist_file} ( UTF_HEADER ); }
         printf {$out_playlist_file} ( "#EXTM3U\n" );
         printf {$out_playlist_file} ( "#PLAYLIST:%s\n\n",$playlistname);
      } elsif ($options{"cplaylist"} == 2) {
         # pls-header
         $out_playlist_utf = 0;
         if ($out_playlist_utf == 1) { printf {$out_playlist_file} ( UTF_HEADER ); }
         printf {$out_playlist_file} ( "[playlist]\n" );
         $out_playlist_pls_items = 0;
      } elsif ($options{"cplaylist"} == 3) {
         #binmode($out_playlist_file, ":utf8");
         $out_playlist_utf = 1;
         if ($out_playlist_utf == 1) { printf {$out_playlist_file} ( UTF_HEADER ); }
         printf {$out_playlist_file} ( "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" );
         printf {$out_playlist_file} ( "<playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\">\n" );
         printf {$out_playlist_file} ( "<trackList>\n" );
      }
   }
   sub playlist_add{
      if (!$options{"cplaylist"}) { return; }
      my ($location, $title) = (shift, shift);
      my $bp=File::Spec->catfile( getcwd, $base_path );
      if ($options{"cplaylist"} == 1) {
         # m3u format
            if ($out_playlist_utf == 1) {
               no warnings 'utf8';
               $location = ".".str_replace($bp,"",$location);
               $location =~ s{\\}{/}g;
               $location = $helper_locale->decode_from_filesystem($location);
               printf {$out_playlist_file} ( "#EXTINF:-1,%s\n", $title );
               printf {$out_playlist_file} ( "%s\n", $location );
               use warnings 'utf8';
            } else {
               my $t_title = $helper_locale->convert_to_filesystem($title);
               $location = ".".str_replace($bp,"",$location);
               $location =~ s{\\}{/}g;
               printf {$out_playlist_file} ( "#EXTINF:-1,%s\n", $t_title );
               printf {$out_playlist_file} ( "%s\n", $location );
            }
      } elsif ($options{"cplaylist"} == 2) {
         # pls format
            if ($out_playlist_utf == 1) {
               no warnings 'utf8';
               $out_playlist_pls_items = $out_playlist_pls_items +1;
               $location = ".".str_replace($bp,"",$location);
               $location =~ s{\\}{/}g;
               $location = $helper_locale->decode_from_filesystem($location);
               printf {$out_playlist_file} ( "File%d=%s\n", $out_playlist_pls_items, $location );
               printf {$out_playlist_file} ( "Title%d=%s\n", $out_playlist_pls_items, $title );
               printf {$out_playlist_file} ( "Length%d=%d\n", $out_playlist_pls_items, -1 );
               use warnings 'utf8';
            } else {
               my $t_title = $helper_locale->convert_to_filesystem($title);
               $out_playlist_pls_items = $out_playlist_pls_items +1;
               $location = ".".str_replace($bp,"",$location);
               $location =~ s{\\}{/}g;
               printf {$out_playlist_file} ( "File%d=%s\n", $out_playlist_pls_items, $location );
               printf {$out_playlist_file} ( "Title%d=%s\n", $out_playlist_pls_items, $t_title );
               printf {$out_playlist_file} ( "Length%d=%d\n", $out_playlist_pls_items, -1 );
            }
      } elsif ($options{"cplaylist"} == 3) {
         # xspf format
            if ($out_playlist_utf == 1) {
               no warnings 'utf8';
               $location = str_replace($bp."\\","",$location);
               use URI::Escape;
               $location = uri_escape($location);
               $location =~ s{\%5C}{/}g;
               printf {$out_playlist_file} ( "<track xml:base=\"./\">\n\t<location>%s</location>\n</track>\n", $location);
               use warnings 'utf8';
            } else {
               $location = str_replace($bp."\\","",$location);
               use URI::Escape;
               $location = uri_escape($location);
               $location =~ s{\%5C}{/}g;
               printf {$out_playlist_file} ( "<track xml:base=\"./\">\n\t<location>%s</location>\n</track>\n", $location);
            }
      }
      return;
   }
   sub playlist_finish{
      if (!$options{"cplaylist"}) { return; }
      $out_playlist_started = $out_playlist_started-1;
      if (!$out_playlist_file) {
         return;
      } else {
         if ($out_playlist_started == 0) {
            if ($options{"cplaylist"} == 1) {
            } elsif ($options{"cplaylist"} == 2) {
               printf {$out_playlist_file} ( "NumberOfEntries=%d\n", $out_playlist_pls_items);
               printf {$out_playlist_file} ( "Version=2\n" );
            } elsif ($options{"cplaylist"} == 3) {
               printf {$out_playlist_file} ( "</trackList>\n" );
               printf {$out_playlist_file} ( "</playlist>\n" );
            }
            close($out_playlist_file);
            $helper_locale->print("Playlist was saved as \"".$out_playlist_file_name_full."\"");
         }
      }
   }
   sub update_id3tag{
      my ($path, $album, $artist, $title, $cover_url) = (shift, shift, shift, shift, shift);
      my $mp3_cover;
      my $if_mp3_cover = 0;
      # get cover from website
      if ($options{"skip_cover"} != 1) {
         #300 460 700
         $cover_url =~ s{%%}{460x460}g;
         $mp3_cover = $helper_http_client->ua->get($cover_url => { Referer => $helper_http_client->ref_url } );
         if ($mp3_cover->error) {
            $if_mp3_cover = 0;
         } else {
            $if_mp3_cover = 1;
            $mp3_cover = $mp3_cover->res->body;
         }
      } else { $helper_locale->print("  skip cover: ".$cover_url); }
      my $mp3 = MP3::Tag->new($path);
      $mp3->get_tags();
      $mp3->{ID3v2}->remove_tag() if exists $mp3->{ID3v2};
      my $id3v2 = $mp3->new_tag("ID3v2");
      $id3v2->add_frame("TALB", $album);         # album
      $id3v2->add_frame("TPE1", $artist);        # artist
      $id3v2->add_frame("TIT2", $title);         # title
      if ($if_mp3_cover) {
         $id3v2->add_frame("APIC", 0, 'image/jpg', chr(0x0), 'Cover (front)', $mp3_cover);
      }
      $id3v2->write_tag;
      $mp3->close();
      return;
   }
   sub save_track {
      my ($track_hash, $num, $album_artist, $cover_url) = (shift, shift, shift, shift);
      $num = sprintf("%.*d", 3, $num);
      my $i=0;
      my $title = $track_hash->{title};
      my $artist="";
      if ($track_hash->{artist}) {
         $artist = $track_hash->{artist};
      } else {
         for my $artists (@{$track_hash->{artists}}){
            if ($i == 0) {
               $artist = $artists->{name};
            } else {
               $artist = $artist.", ".$artists->{name};
            }
            $i+=1;
         }
      }
      my $album="";
      if ($track_hash->{album}) {
         $album = $track_hash->{album};
      } else {
         $i=0; 
         for my $albums (@{$track_hash->{albums}}){
            if ($i == 0) {
               $album = $albums->{title};
            } else {
               $album = $album.", ".$albums->{title};
            }
            $i+=1;
         }
      }
      $artist =~ s{/}{ }g;
      $title =~ s{/}{ }g;
      $album =~ s{/}{ }g;
      $album_artist = $artist if (!$album_artist);
      my $storageDir;
      if ($track_hash->{storage_dir}) {
         $storageDir = $track_hash->{storage_dir};
      } else {
         $storageDir = $track_hash->{storageDir};
      }
      if (!length $storageDir) { $helper_locale->print("  ! Unable to get URL and metadata for the track \"".$artist."\" - \"".$title."\" (\"".$album."\")"); return; }
      my $mp3_url = $helper_http_client->generate_track_url_path($storageDir, $track_hash->{id});
      my $mp3_local_dir = get_track_local_dir();
      my $mp3_local = get_track_local_path($mp3_local_dir, $artist, $title, $num);
      my $tmp_string;
      $tmp_string = $helper_locale->convert_to_filesystem($mp3_local_dir);
      if (!$options{"tags_only"}) { make_path($tmp_string) unless -d $tmp_string; }
      $tmp_string = $mp3_local;
      $mp3_local = $helper_locale->convert_to_filesystem($mp3_local);
      $mp3_local =~ s/\?/_/g;
      if (!$options{"tags_only"}) { 
         playlist_add($mp3_local, $artist." - ". $title);
         if (-f $mp3_local) { 
            $helper_locale->print("  ! File already exists: " . $tmp_string);
            return undef if -f $mp3_local;
         }
         $helper_locale->print("  > Downloading file \"".$artist."\": \"".$title."\"");
         my $tx_mp3 = $helper_http_client->download_file_conent($mp3_url);
         save_file($mp3_local, $tmp_string, $tx_mp3);
         update_id3tag($mp3_local, $album, $album_artist, $title, $cover_url);
      } else {
         if (-f $mp3_local) {
            playlist_add($mp3_local, $artist." - ". $title);
            $helper_locale->print( "  i Updating tag for the file: ".$tmp_string);
            update_id3tag($mp3_local, $album, $album_artist, $title, $cover_url);
         } else {
            $helper_locale->print('  ! File does not exist: ' . $tmp_string);
         }
      }
   }
}
1;
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
package main;
my $ymd;
$ymd = new YaMusicDownloader;
$ymd->parse_input();
