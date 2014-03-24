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

# global variables:
my %g_STATUS_CODE = ( 'OK' => '0', 'WARNING' => '1', 'CRITICAL' => '2', 'UNKNOWN' => '3' );
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

has artist_albums_url =>  sub { Mojo::URL->new('http://music.yandex.ru/get/artist_albums_list.xml?artist=0'); };
has playlist_url =>  sub { Mojo::URL->new('http://music.yandex.ru/get/playlist2.xml?kinds=o&owner=own'); };
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
has ya_login => "";								# yandex login
has ya_password => "";							# yandex password

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
	my $tx = $self->ua->get($playlist_url);
	warn 'ERROR get get_playlist_tracks for ' . $playlist_id . ' : ' . $tx->error and return undef if $tx->error;
	#return $tx->res->json;
	
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
sub update_id3tag {
	
	return
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Dowload and save track with path: <Artist>/<Date>-<Album>/<Num>-<Track>
#  params: $track_hash
sub save_track {
	my ($self, $track_hash) = (shift, shift);
	
	my $artist = $track_hash->{artist};
	$artist =~ s{/}{ }g;
	my $title = $track_hash->{title};
	$title =~ s{/}{ }g;
	my $album = $track_hash->{album};
	$album =~ s{/}{ }g;
	my $cover = $track_hash->{cover};
	
	my $info_url_mp3 = $self->info_url . $track_hash->{storage_dir} . '/2.mp3?nc=' . rand;
	my $tx_info = $self->ua->get($info_url_mp3 => { Referer => $self->ref_url });
	say 'ERROR GET INFO URL: ' . $tx_info->error and return undef if $tx_info->error;
	
	my $dom_host = $tx_info->res->dom->at('download-info regional-host') || $tx_info->res->dom->at('download-info host');
	my $mp3_host = $dom_host->text;
	my $mp3_s = $tx_info->res->dom->at('download-info s')->text;
	my $mp3_ts = $tx_info->res->dom->at('download-info ts')->text;
	
	my $mp3_path = $tx_info->res->dom->at('download-info path')->text;
	
	my $ya_hash = substr($mp3_path,1) . $mp3_s;
	my $rpath = $self->ya_get_hash($ya_hash);
	
	my $mp3_url = 'http://' . $mp3_host . '/get-mp3/' . $rpath . '/' . $mp3_ts  . $mp3_path . '?track-id=' . $track_hash->{id} . '&from=service-10-track-album&similarities-experiment=default';
	
	
	my $mp3_local_path;
	if ($self->create_subdirectories) {
		$mp3_local_path = File::Spec->catfile( getcwd, $self->save_path );
	} else {
		$mp3_local_path = File::Spec->catfile( getcwd, $self->base_path );
	}
	if ($mp3_local_path =~ /\.{1,}$/) {
		$mp3_local_path =~ s/\.{1,}$//g;
	}
	
	my $tmp_string = Encode::encode('cp1251', $mp3_local_path);
	make_path($tmp_string) unless -d $tmp_string;
	my $mp3_local = File::Spec->catfile($mp3_local_path, $artist . ' - ' . $title . '.mp3');
	
	$tmp_string = $mp3_local;
	$tmp_string = Encode::encode('cp866', $tmp_string);
	$mp3_local = Encode::encode('cp1251', $mp3_local);
	say 'Getting file ' . $tmp_string . ' <<< ' . $mp3_url;
	say 'File already exists: ' . $tmp_string and return undef if -f $mp3_local;
	
	my $tx_mp3 = $self->ua->get($mp3_url => { Referer => $self->ref_url } );
	say 'ERROR GET MP3: ' . $tx_mp3->error and return undef if $tx_mp3->error;
	
	open(my $mp3h, '>', $mp3_local);
	binmode($mp3h);
	print $mp3h $tx_mp3->res->body;
	close($mp3h);
	
	# update id3 tags
	my $mp3_cover;
	my $if_mp3_cover = 0;
		# get cover from website
	if ($cover =~ /\.30x30\.(jpg|gif|png)$/i && $self->get_cover) { 
		$cover =~ s/\.30x30\./\.460x460\./g;
		$mp3_cover = $self->ua->get($cover => { Referer => $self->ref_url } );
		if ($mp3_cover->error) {
			$if_mp3_cover = 0;
		} else {
			$if_mp3_cover = 1;
			$mp3_cover = $mp3_cover->res->body;
		}
	}
	my $mp3 = MP3::Tag->new($mp3_local);
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
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Dowload and save track for playlist with path: <PlaylistOwner>/<PlaylistID>-<PlaylistName>/<Num>-<Artist>-<Title>
#  params: $track_hash, $num
sub save_track_playlist {
	my ($self, $track_hash, $num) = (shift, shift, shift);
	
	$num = sprintf("%.*d", 3, $num);
	
	my $artist = $track_hash->{artist};
	$artist =~ s{/}{ }g;
	my $title = $track_hash->{title};
	$title =~ s{/}{ }g;
	my $album = $track_hash->{album};
	$album =~ s{/}{ }g;
	my $cover = $track_hash->{cover};
	
	my $info_url_mp3 = $self->info_url . $track_hash->{storage_dir} . '/2.mp3?nc=' . rand;
	my $tx_info = $self->ua->get($info_url_mp3 => { Referer => $self->ref_url });
	say 'ERROR GET INFO URL: ' . $tx_info->error and return undef if $tx_info->error;
	
	my $dom_host = $tx_info->res->dom->at('download-info regional-host') || $tx_info->res->dom->at('download-info host');
	my $mp3_host = $dom_host->text;
	my $mp3_s = $tx_info->res->dom->at('download-info s')->text;
	my $mp3_ts = $tx_info->res->dom->at('download-info ts')->text;
	
	my $mp3_path = $tx_info->res->dom->at('download-info path')->text;
	
	my $ya_hash = substr($mp3_path,1) . $mp3_s;
	my $rpath = $self->ya_get_hash($ya_hash);
	
	my $mp3_url = 'http://' . $mp3_host . '/get-mp3/' . $rpath . '/' . $mp3_ts  . $mp3_path . '?track-id=' . $track_hash->{id} . '&from=service-10-track-album&similarities-experiment=default';
	
	my $mp3_local_path;
	if ($self->create_subdirectories) {
		$mp3_local_path = File::Spec->catfile( getcwd, $self->save_path );
	} else {
		$mp3_local_path = File::Spec->catfile( getcwd, $self->base_path );
	}
	if ($mp3_local_path =~ /\.{1,}$/) {
		$mp3_local_path =~ s/\.{1,}$//g;
	}
	my $tmp_string;
	$tmp_string = $mp3_local_path;
	$tmp_string = Encode::encode('cp1251', $tmp_string);
	make_path($tmp_string) unless -d $tmp_string;
	my $mp3_local = File::Spec->catfile($mp3_local_path, $num.' - '. $artist . ' - ' . $title . '.mp3');
	
	$tmp_string = $mp3_local;
	$tmp_string = Encode::encode('cp866', $tmp_string);
	$mp3_local = Encode::encode('cp1251', $mp3_local);
	$mp3_local =~ s/\?/_/g;
	
	open( FILE, ">>" . "log.txt" )
		or die "\nCan't open file for writing: $!";
	printf FILE ( "file: %s\n", $mp3_local );
	close(FILE);
	
	say 'Getting file ' . $tmp_string . ' <<< ' . $mp3_url;
	say 'File already exists: ' . $tmp_string and return undef if -f $mp3_local;
	
	my $tx_mp3 = $self->ua->get($mp3_url => { Referer => $self->ref_url } );
	say 'ERROR GET MP3: ' . $tx_mp3->error and return undef if $tx_mp3->error;
	
	open(my $mp3h, '>', $mp3_local);
	binmode($mp3h);
	print $mp3h $tx_mp3->res->body;
	close($mp3h);
	
	# update id3 tags
	my $mp3_cover;
	my $if_mp3_cover = 0;
		# get cover from website
	if ($cover =~ /\.30x30\.(jpg|gif|png)$/i && $self->get_cover) { 
		$cover =~ s/\.30x30\./\.460x460\./g;
		$mp3_cover = $self->ua->get($cover => { Referer => $self->ref_url } );
		if ($mp3_cover->error) {
			$if_mp3_cover = 0;
		} else {
			$if_mp3_cover = 1;
			$mp3_cover = $mp3_cover->res->body;
		}
	}
	my $mp3 = MP3::Tag->new($mp3_local);
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
	for my $track_hash (@{$playlist_hash->{tracks}}){
		$i+=1;
		$self->save_track_playlist( $track_hash, $i );
		#print_hash($track_hash);
	}
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# download full album by album_id
#  params: $album_id
#  <Artist>/<Album>/<Artist - Track>
sub download_album {
	my ($self, $album_id) = (shift, shift);
	
	my $album_hash = $self->get_album_tracks( $album_id );
	my $i = 0;
	for my $track_hash (@{$album_hash->{tracks}}){
		if ($i == 0) { 
			my $artist = $track_hash->{artist};
			# hierarchy: "base_dir/artist/album/artist - track.mp3"
			$self->save_path($self->base_path ."". $self->strip_slashes($artist) ."/". $self->strip_slashes($track_hash->{album}) ."/"); 
		}
		$i+=1;
		#print_hash($track_hash);
		$self->save_track( $track_hash );
	}
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
		#print_hash($track_hash);
		$self->save_track( $track_hash );
	}
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# download all albums of artist by artist_id
#  params: $artist_id
sub download_artist {
	my ($self, $artist_id) = (shift, shift);
	
	my $albums_hash = $self->get_artist_albums( $artist_id );
	
	for my $album_id (@{$albums_hash->{albums}}){
		$self->download_album($album_id);
	}
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

my $albums = "";
my $artists = "";
my $tracks = "";
my $playlist = "";
my $directory = "";
my $no_subdirectories = 0;
my $get_cover = 0;
my $force_album = "";

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
    
    Options:
    -c or --cover 
        - get cover for each track from Yandex.Music and add it as ID3v2 tag
    --dir=DIRECTORY
        - set output directory. Default value: ./ya.music/
    -ns or --no_subdirectories
        - do not create subdirectories (ie. "artist/album/atrist - track"), save
        only to output directory (see option --dir)
    --help
        - print this help

    Samples:
        $0 --albums=295708,295709,295710 -c --dir=./
        $0 --artists=3120,79215 --cover
        $0 --tracks=2749751,2295002,1710808,1710811,1710816,2295010,2758009 -c -ns --dir="./Queen/favorites/" 
        $0 --playlist="1008&ya-playlist"
EOH
	exit $g_STATUS_CODE{"OK"};
}

GetOptions(
	"albums=s"    => \$albums,
	"artists=s"  => \$artists,
	"tracks=s"   => \$tracks,
	"playlist=s" => \$playlist,
	"dir=s",     => \$directory,
	"c|cover"    => \$get_cover,
	"ns|no_subdirectories" => \$no_subdirectories,
	"fa|force_album"       => \$force_album,
) or print_usage;

print_usage unless $albums || $artists || $tracks || $playlist;

my $ymd = YaMusicDownloader->new;
# update options
$ymd->set_base_path($directory);
$ymd->create_subdirectories(0) if $no_subdirectories == 1;
$ymd->get_cover(1) if $get_cover == 1;

no warnings 'numeric';
for my $artist (split /\D/, $artists){
	next unless (int($artist));
	#say 'Found artist id ' . $artist;
	$ymd->download_artist($artist);
}

for my $album (split /\D/, $albums){
	next unless (int($album));
	#say 'Found album id ' . $album;
	$ymd->download_album($album);
}

for my $track (split /\D/, $tracks){
	next unless (int($track));
	#say 'Found track id ' . $track;
	$ymd->download_track($track);
}
if ($playlist =~ /.*\&.*/) {
#	#say 'Found playlist ' . $playlist;
	$ymd->download_playlist($playlist);
}