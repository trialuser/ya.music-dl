#!/usr/bin/perl -w
package YaMusicDownloader;
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::JSON;
use Mojo::DOM;
use Mojo::URL;
use POSIX qw(strftime);
use autodie;
use Cwd;
use File::Spec;
use File::Path qw/make_path/;
use MP3::Tag;
use Digest::MD5 qw(md5_hex);
#use utf8;

$ENV{MOJO_MAX_MESSAGE_SIZE} = 9_999_999_999;
use constant UTF_HEADER => "\x{00EF}\x{00BB}\x{00BF}";

# global variables:
my %g_STATUS_CODE = ( 'OK' => '0', 'WARNING' => '1', 'CRITICAL' => '2', 'UNKNOWN' => '3' );
my %g_playlist_formats = ( 0=>'no', 1=>'m3u', 2=>'pls', 3=>'xspf' );
my $g_now=time;
# # # # #

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

has ya_auth_url => 'http://passport.yandex.ru/passport?mode=embeddedauth&from=music&retpath=http%3A%2F%2Fmusic.yandex.ru%2Fxml%2Flogin-status.xml';
has artist_albums_url =>  sub { Mojo::URL->new('http://music.yandex.ru/get/artist_albums_list.xml?artist=0'); };
has playlist_url =>  sub { Mojo::URL->new('http://music.yandex.ru/get/playlist2.xml?kinds=o&owner=own'); };
#has playlist_url =>  'http://music.yandex.ru/get/playlist2.xml?kinds=o&owner=own';
has playlist_url_tracks =>  sub { Mojo::URL->new('http://music.yandex.ru/get/tracks.xml?tracks=0'); };
has track_url =>  sub { Mojo::URL->new('http://music.yandex.ru/external/embed-track.xml?track-id=0'); };
has album_tracks_url =>  'http://music.yandex.ru/fragment/album/';
has info_url => 'http://storage.music.yandex.ru/download-info/';
has ref_url => 'http://swf.static.yandex.net/music/service-player.swf?v=12.27.1&proxy-host=http://storage.music.yandex.ru';
has base_path => './ya.music/';					# absolute path (like a constant, but can be changed with option --dir)
has save_path => './ya.music/';					# where to store files (can include artist name and album name in path)
has create_subdirectories => 1;					# create subdirectories, ie.: using artist name and album name in path
has get_cover => 0;								# get cover from website?
has use_cookie => 0;							# login and use cookies?
has ya_login => "login";						# yandex login
has ya_password => "password";				# yandex password
has encoding_console => "cp866";				# 
has encoding_filesystem => "cp1251";			# 
has proxy_url => "http://127.0.0.1:8086";		# proxy url
has tags_only => 0;								# download only id3v2 tags or whole files?
has out_playlist_type => 0;						# create playlist
has out_playlist_file => 0;						# playlist file descriptor
has out_playlist_file_name => 0;				# playlist file name
has out_playlist_file_name_full => "";			# playlist full file name
has out_playlist_started => 0;					# do not create duplicates

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# print a variable with a type %hash
# 
sub print_hash {
	my $href = shift;
	while( my( $key, $val ) = each %{$href} ) {
		print " $key\t=>$val\n";
	}
	print "\n";
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
#
sub strip_slashes {
	my ($self, $data) = (shift, shift);
	if (!$data) {
		return "";
	} else {
		$data =~ s{/}{ }g;
		return $data;
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
#
# Replace  a  string   without  using  RegExp .
sub str_replace  {
	my $replace_this = shift;
	my $with_this  = shift; 
	my $string    = shift;
	
	my $length = length($string);
	my $target = length($replace_this);
	
	for(my $i=0; $i<$length - $target + 1; $i++) {
		if(substr($string,$i,$target) eq $replace_this) {
			$string = substr($string,0,$i) . $with_this . substr($string,$i+$target);
			return $string; #Comment this if you what a global replace
		}
	}
	return $string;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
#
sub set_proxy {
	my ($self, $proxy) = (shift, shift);
	$self->proxy_url("http://".$proxy);
	return;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
#
sub yandex_login {
	my ($self, $login, $password) = (shift, shift, shift);
	my $TS = time;
	$self->ya_login = $login;
	$self->ya_password = $password;
	my $proxy = Mojo::UserAgent::Proxy->new;
	$proxy->http($self->proxy_url);
	$self->ua->proxy($proxy);
	#$self->ua->max_redirects(1);
	my $tx = $self->ua->post($self->ya_auth_url => form => {
		login => $self->ya_login,
		passwd => $self->ya_password,
		password => $self->ya_password,
		twoweeks => "yes",
		timestamp => $TS});
	if (my $res = $tx->success) { 
		# body:
		#print "body:". $res->body."\n";
		
		# headers:
		#my $headers = $res->headers;
		#for my $header ($headers->header('Set-Cookie')) {
		#	say 'Set-Cookie:';
		#	say for @$header;
		#}
		
		# cookies:
		#my $jar = Mojo::UserAgent::CookieJar->new;
		#$jar->extract($tx);
		#for my $cookie ($jar->all) {
		#	print $cookie->name.": ". $cookie->value;
		#}
	} else {
		my ($err, $code) = $tx->error;
		say $code ? "$code response: $err" : "Connection error: $err";
	}
#ya_auth_url;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# set base_path
#   params: $dir
sub set_base_path {
	my ($self, $dir) = (shift, shift);
	if ($dir =~ /^[-\w\.\/]+$/) {
		$self->base_path($dir);
	}
	return;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
#
sub playlist_start {
	my ($self, $playlistname) = (shift, shift);
	my $t_filename;
	my $f;
	
	$self->out_playlist_started($self->out_playlist_started+1);
	if ($self->out_playlist_started > 1) { return; }
	if (length($self->out_playlist_file_name) == 0) {
		$playlistname = $playlistname;
	} else {
		$playlistname = $self->out_playlist_file_name;
	}
	my $tmp_string = Encode::encode($self->encoding_filesystem, $self->base_path);
	make_path($tmp_string) unless -d $tmp_string;
	$t_filename = File::Spec->catfile($self->base_path, $playlistname.'.'. $g_playlist_formats{ $self->out_playlist_type });
	$self->out_playlist_file_name_full($t_filename);
	$t_filename = Encode::encode($self->encoding_filesystem, $t_filename);
	#if (-f $t_filename);
	
	open( $f, ">" . $t_filename ) or die "\nCan't open file for writing: $!";
	$self->out_playlist_file ($f);
	if ($self->out_playlist_type == 1) {
		# m3u-header
		has out_playlist_utf=>1;
		if ($self->out_playlist_utf == 1) { printf {$self->out_playlist_file} ( UTF_HEADER ); }
		printf {$self->out_playlist_file} ( "#EXTM3U\n" );
		printf {$self->out_playlist_file} ( "#PLAYLIST:%s\n\n",$playlistname);
	} elsif ($self->out_playlist_type == 2) {
		# pls-header
		has out_playlist_utf=>0;
		if ($self->out_playlist_utf == 1) { printf {$self->out_playlist_file} ( UTF_HEADER ); }
		printf {$self->out_playlist_file} ( "[playlist]\n" );
		has out_playlist_pls_items=>0;
	} elsif ($self->out_playlist_type == 3) {
		#binmode($self->out_playlist_file, ":utf8");
		has out_playlist_utf=>1;
		if ($self->out_playlist_utf == 1) { printf {$self->out_playlist_file} ( UTF_HEADER ); }
		printf {$self->out_playlist_file} ( "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" );
		printf {$self->out_playlist_file} ( "<playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\">\n" );
		printf {$self->out_playlist_file} ( "<trackList>\n" );
	}
	return;
}
sub playlist_finish {
	my ($self) = (shift);
	
	$self->out_playlist_started($self->out_playlist_started-1);
	if (!$self->out_playlist_file) {
		return;
	} else {
		if ($self->out_playlist_started == 0) {
			if ($self->out_playlist_type == 1) {
			} elsif ($self->out_playlist_type == 2) {
				printf {$self->out_playlist_file} ( "NumberOfEntries=%d\n", $self->out_playlist_pls_items);
				printf {$self->out_playlist_file} ( "Version=2\n" );
			} elsif ($self->out_playlist_type == 3) {
				printf {$self->out_playlist_file} ( "</trackList>\n" );
				printf {$self->out_playlist_file} ( "</playlist>\n" );
			}
			close($self->out_playlist_file);
			my $t_filename = Encode::encode($self->encoding_console, $self->out_playlist_file_name_full);
			say "Playlist was saved as ".$t_filename;
		}
	}
}
sub playlist_add {
	my ($self, $location, $title) = (shift, shift, shift);
	my $bp=File::Spec->catfile( getcwd, $self->base_path );
	if ($self->out_playlist_type == 1) {
		# m3u format
			if ($self->out_playlist_utf == 1) {
				no warnings 'utf8';
				$location = ".".str_replace($bp,"",$location);
				$location =~ s{\\}{/}g;
				$location = Encode::decode($self->encoding_filesystem,$location);
				printf {$self->out_playlist_file} ( "#EXTINF:-1,%s\n", $title );
				printf {$self->out_playlist_file} ( "%s\n", $location );
				use warnings 'utf8';
			} else {
				my $t_title = Encode::encode($self->encoding_filesystem, $title);
				$location = ".".str_replace($bp,"",$location);
				$location =~ s{\\}{/}g;
				printf {$self->out_playlist_file} ( "#EXTINF:-1,%s\n", $t_title );
				printf {$self->out_playlist_file} ( "%s\n", $location );
			}
	} elsif ($self->out_playlist_type == 2) {
		# pls format
			if ($self->out_playlist_utf == 1) {
				no warnings 'utf8';
				$self->out_playlist_pls_items($self->out_playlist_pls_items +1);
				$location = ".".str_replace($bp,"",$location);
				$location =~ s{\\}{/}g;
				$location = Encode::decode($self->encoding_filesystem,$location);
				printf {$self->out_playlist_file} ( "File%d=%s\n", $self->out_playlist_pls_items, $location );
				printf {$self->out_playlist_file} ( "Title%d=%s\n", $self->out_playlist_pls_items, $title );
				printf {$self->out_playlist_file} ( "Length%d=%d\n", $self->out_playlist_pls_items, -1 );
				use warnings 'utf8';
			} else {
				my $t_title = Encode::encode($self->encoding_filesystem, $title);
				$self->out_playlist_pls_items($self->out_playlist_pls_items +1);
				$location = ".".str_replace($bp,"",$location);
				$location =~ s{\\}{/}g;
				printf {$self->out_playlist_file} ( "File%d=%s\n", $self->out_playlist_pls_items, $location );
				printf {$self->out_playlist_file} ( "Title%d=%s\n", $self->out_playlist_pls_items, $t_title );
				printf {$self->out_playlist_file} ( "Length%d=%d\n", $self->out_playlist_pls_items, -1 );
			}
	} elsif ($self->out_playlist_type == 3) {
		# xspf format
			if ($self->out_playlist_utf == 1) {
				no warnings 'utf8';
				use URI::Escape;
				$location = uri_escape($location);
				$location =~ s{\%5C}{/}g;
				printf {$self->out_playlist_file} ( "<track xml:base=\"./\">\n\t<location>%s</location>\n</track>\n", $location);
				use warnings 'utf8';
			} else {
				$location = str_replace($bp."\\","",$location);
				use URI::Escape;
				$location = uri_escape($location);
				$location =~ s{\%5C}{/}g;
				printf {$self->out_playlist_file} ( "<track xml:base=\"./\">\n\t<location>%s</location>\n</track>\n", $location);
			}
	}
	return;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# get list of albums for artist 
#  params: $artist_id
sub get_artist_albums {
	my ($self, $artist_id) = (shift, shift);
	
	my $artist_url = $self->artist_albums_url->clone;
	$artist_url->query->param( artist => $artist_id);
	
	my $tx = $self->ua->get($artist_url);
	warn 'ERROR get get_artist_albums for ' . $artist_id . ' : ' . $tx->error and return undef if $tx->error;

	return $tx->res->json;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# get tracks hashes by playlist_id
#  params: $playlist_id, $playlist_owner
sub get_playlist_tracks {
	my ($self, $playlist_id, $playlist_owner) = (shift, shift, shift);
	
	say "downloading playlist: ".$playlist_id.", owner: ".$playlist_owner;
	my $playlist_url = $self->playlist_url->clone;
	$playlist_url->query->param( kinds => $playlist_id);
	$playlist_url->query->param( owner => $playlist_owner);
	
	my $tx = $self->ua->build_tx(GET => $playlist_url->to_string);
	$tx->req->headers->accept('*/*');
	#$tx->req->cookies({yandex_login => 'login'});
	$tx = $self->ua->start($tx);
	
	warn 'ERROR get get_playlist_tracks for ' . $playlist_id . ' : ' . $tx->error and return undef if $tx->error;
	#print $tx->res->body."\n";
	
	my $tracks = $tx->res->json->{playlists}[0]{tracks};
	#$title = Encode::encode('cp1251', $title);
	my $i = 0;
	my $tracks_url="";
	for my $track_id (@{$tracks}){
		$i+=1;
		$tracks_url = $tracks_url .",".$track_id;
	}
	$tracks_url =~ s/^,//;
	
	print "Getting the list, total: ".$i." track(s)\n";
	my $playlist_url_tracks = $self->playlist_url_tracks->clone;
	$playlist_url_tracks->query->param( tracks => $tracks_url);
	my $tx2 = $self->ua->get($playlist_url_tracks);
	warn 'ERROR get get_playlist_tracks for ' . $i . ' track(s) : ' . $tx2->error and return undef if $tx2->error;
	$tx->res->json->{tracks} = $tx2->res->json->{tracks};
	return $tx->res->json;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# get tracks hashes by album_id
#  params: $album_id
#  alternative url: http://music.yandex.ru/get/album_info.jsx?id=0
sub get_album_tracks {
	my ($self, $album_id) = (shift, shift);
	my $album_url = Mojo::URL->new( $self->album_tracks_url . $album_id );
	
	$album_url->query->param( prefix => 'facegen-' . strftime('%Y-%m-%dT00-00-00', localtime));
		
	my $tx = $self->ua->get($album_url => {Referer => $self->ref_url});
	warn 'ERROR get get_album_tracks for ' . $album_url . ' : ' . $tx->error and return undef if $tx->error;
	
	my $res = $tx->res->dom->at('div.js-album');
	unless( $res){
		warn 'ERROR find get_album_tracks for ' . $album_url;
		
		return undef;
	}
	
	$res = $res->{onclick};
	
	#fix content
	utf8::encode($res);
	$res =~ s/^return//;
	$res =~ s/\'(.*?)\':/\"$1\":/g;
	$res = $self->json->decode($res);
	
	return $res;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# get track hash by track_id
#  params: $track_id
sub get_track {
	my ($self, $track_id) = (shift, shift);
	
	# my $track_url = $self->track_url->clone;
	# $track_url->query->param( 'track-id' => $track_id);
	# my $tx = $self->ua->get($track_url);
	# warn 'ERROR get get_track for ' . $track_id . ' : ' . $tx->error and return undef if $tx->error;
	# my $dom = $tx->res->dom;
	# my $track_hash;
	# $track_hash->{'title'} = $tx->res->dom->at('title')->text;
	# $track_hash->{'id'} = $tx->res->dom->at('track')->attr('id');
	# $track_hash->{'artist'} = $tx->res->dom->at('artist')->at('name')->text;
	# $track_hash->{'album'} = $tx->res->dom->at('album')->at('title')->text;
	# $track_hash->{'storage_dir'} = $tx->res->dom->at('track')->attr('storage-dir');
	
	my $playlist_url_tracks = $self->playlist_url_tracks->clone;
	$playlist_url_tracks->query->param( tracks => $track_id);
	my $tx2 = $self->ua->get($playlist_url_tracks);
	warn 'ERROR get get_playlist_tracks for track_id: ' . $track_id . ' : ' . $tx2->error and return undef if $tx2->error;
	#$tx->res->json->{tracks} = $tx2->res->json->{tracks};
	return $tx2->res->json;
	
	
	#return $track_hash;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# generate direct link to mp3-file at Yandex.Music
# 
sub get_track_url_path {
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
	my $rpath = $self->ya_get_hash($ya_hash);
	my $mp3_url = 'http://' . $mp3_host . '/get-mp3/' . $rpath . '/' . $mp3_ts  . $mp3_path . '?track-id=' . $track_id . '&from=service-10-track-album&similarities-experiment=default';
	return $mp3_url;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# generate full path to the local file, exclude filename 
#
sub get_track_local_dir {
	my ($self) = (shift);
	my $mp3_local_path;
	if ($self->create_subdirectories) {
		$mp3_local_path = File::Spec->catfile( getcwd, $self->save_path );
	} else {
		$mp3_local_path = File::Spec->catfile( getcwd, $self->base_path );
	}
	if ($mp3_local_path =~ /\.{1,}$/) {
		$mp3_local_path =~ s/\.{1,}$//g;
	}
	return $mp3_local_path;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# generate full path to the local file, include filename
#
sub get_track_local_path {
	my ($self, $dir, $artist, $title, $num) = (shift, shift, shift, shift, shift, shift);
	my $mp3_local;
	if ($num == -1) {
		$mp3_local = File::Spec->catfile($dir, $artist . ' - ' . $title . '.mp3');
	} else {
		$mp3_local = File::Spec->catfile($dir, $num.' - '. $artist . ' - ' . $title . '.mp3');
	}
	$mp3_local =~ s/\?/_/g;
	return $mp3_local;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# download file by its direct url, return response body
#
sub download_file {
	my ($self, $mp3_url) = (shift, shift);
	my $tx_mp3 = $self->ua->get($mp3_url => { Referer => $self->ref_url } );
	say 'ERROR GET MP3: ' . $tx_mp3->error and return undef if $tx_mp3->error;
	return $tx_mp3->res->body;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# save binary data as file on the local storage
#  params: $path_to_save, $path_to_save_console (encoded to print it in console), $blob
sub save_file {
	my ($self, $path, $path_console, $blob) = (shift, shift, shift, shift);
	say ' > Saving file: '. $path_console;
	open(my $mp3h, '>', $path);
	binmode($mp3h);
	print $mp3h $blob;
	close($mp3h);
	return;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# update id3v2-tags: author, title, album, cover
#
sub update_id3tag {
	my ($self, $path, $album, $artist, $title, $cover) = (shift, shift, shift, shift, shift, shift);
	
	my $mp3_cover;
	my $if_mp3_cover = 0;
		# get cover from website
	if ($cover =~ /^http.*\.30x30\.(jpg|gif|png)$/i && $self->get_cover) { 
		$cover =~ s/\.30x30\./\.460x460\./g;
		$mp3_cover = $self->ua->get($cover => { Referer => $self->ref_url } );
		if ($mp3_cover->error) {
			$if_mp3_cover = 0;
		} else {
			$if_mp3_cover = 1;
			$mp3_cover = $mp3_cover->res->body;
		}
	} else { say "  skip cover: ".$cover; }
	my $mp3 = MP3::Tag->new($path);
	$mp3->get_tags();
	$mp3->{ID3v2}->remove_tag() if exists $mp3->{ID3v2};
	my $id3v2 = $mp3->new_tag("ID3v2");
	$id3v2->add_frame("TALB", $album);			# album
	$id3v2->add_frame("TPE1", $artist);			# artist
	$id3v2->add_frame("TIT2", $title);			# title
	if ($if_mp3_cover) {
		$id3v2->add_frame("APIC", 0, 'image/jpg', chr(0x0), 'Cover (front)', $mp3_cover);
	}
	$id3v2->write_tag;
	$mp3->close();
	return;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Dowload and save track with path: <Artist>/<Date>-<Album>/<Num>-<Track>
#  params: $track_hash, $track_num (!=-1 for playlist mode, =-1 for all other download modes)
sub save_track {
	my ($self, $track_hash, $num) = (shift, shift, shift);
	
	$num = sprintf("%.*d", 3, $num);
	my $artist = $track_hash->{artist};
	my $title = $track_hash->{title};
	my $album = $track_hash->{album};
	my $cover = $track_hash->{cover};
	$artist =~ s{/}{ }g;
	$title =~ s{/}{ }g;
	$album =~ s{/}{ }g;
	
	my $mp3_url = $self->get_track_url_path($track_hash->{storage_dir}, $track_hash->{id});
	my $mp3_local_dir = $self->get_track_local_dir();
	my $mp3_local = $self->get_track_local_path($mp3_local_dir, $artist, $title, $num);
	my $tmp_string;
	
	$tmp_string = Encode::encode($self->encoding_filesystem, $mp3_local_dir);
	if (!$self->tags_only) { make_path($tmp_string) unless -d $tmp_string; }
	
	$tmp_string = Encode::encode($self->encoding_console, $mp3_local);
	$mp3_local = Encode::encode($self->encoding_filesystem, $mp3_local);
	$mp3_local =~ s/\?/_/g;
	
	if (!$self->tags_only) { 
		$self->playlist_add($mp3_local, $artist." - ". $title);
		say 'File already exists: ' . $tmp_string and return undef if -f $mp3_local;
		my $tx_mp3 = $self->download_file($mp3_url);
		$self->save_file($mp3_local, $tmp_string, $tx_mp3);
		$self->update_id3tag($mp3_local, $album, $artist, $title, $cover);
	} else {
		if (-f $mp3_local) {
			$self->playlist_add($mp3_local, $artist." - ". $title);
			say "Updating tag for the file: ".$tmp_string;
			#say "  tags: ".$album.", ".$artist.", ".$title.", ".$cover;
			$self->update_id3tag($mp3_local, $album, $artist, $title, $cover);
		} else {
			say 'File does not exist: ' . $tmp_string;
		}
	}
	return;
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# download full playlist by playlist_id and playlist_owner
#  params: $playlist (format: "playlist_id&owner")
#  <PlaylistOwner>/<PlaylistID>-<PlaylistName>/<Num>-<Artist>-<Title>
sub download_playlist {
	my ($self, $playlist) = (shift, shift);
	$playlist =~ m/^(\d*)/;
	my $playlist_id = $1;
	$playlist =~ m/^\d*\&(.*)$/;
	my $playlist_owner = $1;
	
	my $playlist_hash = $self->get_playlist_tracks( $playlist_id, $playlist_owner);
	
	my $title = $playlist_hash->{playlists}[0]{title};
	#$title = Encode::encode('cp1251', $title);
	# hierarchy: "base_dir/@playlist_owner/id - title/id - artist - track.mp3"
	$self->save_path($self->base_path."@".$playlist_owner."/".$playlist_id." - ".$self->strip_slashes($title)."/");
	my $i = 0;
	
	$self->playlist_start("@".$playlist_owner."-".$playlist_id);
	for my $track_hash (@{$playlist_hash->{tracks}}){
		$i+=1;
		$self->save_track( $track_hash, $i );
	}
	$self->playlist_finish();
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# download full album by album_id
#  params: $album_id
#  <Artist>/<Album>/<Artist - Track>
sub download_album {
	my ($self, $album_id) = (shift, shift);
	
	my $album_hash = $self->get_album_tracks( $album_id );
	my $i = 0;
	
	$self->playlist_start("Album - ".$album_id);
	for my $track_hash (@{$album_hash->{tracks}}){
		if ($i == 0) { 
			my $artist = $track_hash->{artist};
			# hierarchy: "base_dir/artist/album/artist - track.mp3"
			$self->save_path($self->base_path ."". $self->strip_slashes($artist) ."/". $self->strip_slashes($track_hash->{album}) ."/"); 
		}
		$i+=1;
		$self->save_track( $track_hash, -1 );
	}
	$self->playlist_finish();
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# download a one track by track_id
#  params: $track_id
#  <Artist>/<Album>/<Artist - Track>
sub download_track {
	my ($self, $track_id) = (shift, shift);
	my $track_hashs = $self->get_track($track_id);
	my $i = 0;
	
	for my $track_hash (@{$track_hashs->{tracks}}){
		if ($i == 0) { 
			my $artist = $track_hash->{artist};
			# hierarchy: "base_dir/artist/album/artist - track.mp3"
			$self->save_path($self->base_path ."". $self->strip_slashes($artist) ."/". $self->strip_slashes($track_hash->{album}) ."/"); 
		}
		$i+=1;
		$self->save_track( $track_hash, -1 );
	}
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# download all albums of artist by artist_id
#  params: $artist_id
sub download_artist {
	my ($self, $artist_id) = (shift, shift);
	
	my $albums_hash = $self->get_artist_albums( $artist_id );
	
	$self->playlist_start("Artist - ".$artist_id);
	for my $album_id (@{$albums_hash->{albums}}){
		$self->download_album($album_id);
	}
	$self->playlist_finish();
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Yandex Helper: crypto functions from Yandex
#  URL to source JS library: http://music.yandex.ru/index.min.js?build=14.01.04fix02
sub ya_get_hash{
        my $self = shift;
        my $str = shift;
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
1;
########################################################################
package main;
use Getopt::Long;
#use utf8;

sub print_usage{
	print <<EOH;
   Usage: $0 [command] [options]
   
   Commands:
    --albums=IDS_LIST
        - download all tracks from album by album_ID (comma separated)
    --artists=IDS_LIST
        - download all albums by artist_ID (comma separated)
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
        - get cover for each track from Yandex.Music and add it as ID3v2 tag
    --dir=DIRECTORY
        - set output directory. Default value: ./ya.music/
    -ns or --no_subdirectories
        - do not create subdirectories (ie. "artist/album/atrist - track"), save
        only to output directory (see option --dir)
    -to or --tags_only
        - do not downloads tracks, update only ID3v2 tags for existing files
        Note: not existing files will be skipped
    --cp=FORMAT_ID
        - create playlist-file. Available formats: m3u (id=1), pls (id=2)
    --cp-name=NAME
        - set the name for playlist-file (without extension). NAME - english only!
    --help
        - print this help

    Samples:
        $0 --albums=295708,295709,295710 -c --dir=./
        $0 --artists=3120,79215 --proxy="192.168.50.1:8080"
        $0 --artists=3120,79215 --cover --tags_only
        $0 --tracks=2749751,2295002,1710808,1710811,1710816,2295010,2758009 -c -ns --dir="./Queen/favorites/" 
        $0 --playlist="1008&ya-playlist" --login=my_yandex_login --password=secret
        $0 --tracks=2749751,2295002,1710808,1710811,1710816,2295010,2758009 -c -ns --dir="./MyPlaylists/" --cp=1 --cp-name=Queen
EOH
	exit $g_STATUS_CODE{"OK"};
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# declare variables:
#
my $ymd;
my $o_albums = "";
my $o_artists = "";
my $o_tracks = "";
my $o_playlist = "";
my $o_directory = "";
my $o_no_subdirectories = 0;
my $o_tags_only = 0;
my $o_get_cover = 0;
my $o_login="";
my $o_password="";
my $o_proxy="";
my $o_cplaylist=0;
my $o_cplaylist_name="";
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
#     PARSE OPTIONS:
#
GetOptions(
	"albums=s"   => \$o_albums,
	"artists=s"  => \$o_artists,
	"tracks=s"   => \$o_tracks,
	"playlist=s" => \$o_playlist,
	"dir=s",     => \$o_directory,
	"c|cover"    => \$o_get_cover,
	"ns|no_subdirectories" => \$o_no_subdirectories,
	"to|tags_only"         => \$o_tags_only,
	"login=s"    => \$o_login,
	"password=s" => \$o_password,
	"proxy=s"    => \$o_proxy,
	"cp=i"       => \$o_cplaylist,
	"cp-name=s"  => \$o_cplaylist_name,
) or print_usage;
print_usage unless $o_albums || $o_artists || $o_tracks || $o_playlist;
	
	$ymd = YaMusicDownloader->new;
	
	# update options
	$ymd->set_base_path($o_directory);
	$ymd->create_subdirectories(0) if $o_no_subdirectories == 1;
	$ymd->get_cover(1) if $o_get_cover == 1;
	no warnings 'numeric';
	
	if ($o_proxy && $o_proxy =~ /^[a-zA-Z0-9\.-]{1,}\:[0-9]{1,5}$/) {
		$ymd->set_proxy($o_proxy);
	} else { say "Proxy \"".$o_proxy."\" is invalid" if $o_proxy; }
	if ($o_login && $o_password) { 
		$ymd->use_cookie(1);
		$ymd->yandex_login($o_login,$o_password); 
	}
	$ymd->tags_only($o_tags_only);
	if ($o_cplaylist < 0 or $o_cplaylist > scalar(keys %g_playlist_formats)) {
		$ymd->out_playlist_type(0);
	} else {
		$ymd->out_playlist_type($o_cplaylist);
		if ($o_cplaylist_name) {
			$ymd->out_playlist_file_name($o_cplaylist_name);
		} else { 
			$ymd->out_playlist_file_name( "" );
		}
	}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# download modes:
	for my $artist (split /\D/, $o_artists){
		next unless (int($artist));
		$ymd->download_artist($artist);
	}
	for my $album (split /\D/, $o_albums){
		next unless (int($album));
		$ymd->download_album($album);
	}
	if ($o_playlist =~ /.*\&.*/) {
		$ymd->download_playlist($o_playlist);
	}
	if ($o_tracks) {
		$ymd->playlist_start("Playlist - ".$g_now);
		for my $track (split /\D/, $o_tracks){
			next unless (int($track));
			$ymd->download_track($track);
		}
		$ymd->playlist_finish();
	}
exit 0;