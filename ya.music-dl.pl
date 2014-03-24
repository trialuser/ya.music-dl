#!/usr/bin/perl -w
package YandexMusikDownloader;
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
#use utf8;

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

has artist_albums_url =>  sub { Mojo::URL->new('http://music.yandex.ru/get/artist_albums_list.xml?artist=0'); };
has playlist_url =>  sub { Mojo::URL->new('http://music.yandex.ru/get/playlist2.xml?kinds=o&owner=own'); };
has track_url =>  sub { Mojo::URL->new('http://music.yandex.ru/external/embed-track.xml?track-id=0'); };
has album_tracks_url =>  'http://music.yandex.ru/fragment/album/';
has info_url => 'http://storage.music.yandex.ru/download-info/';
has ref_url => 'http://swf.static.yandex.net/music/service-player.swf?v=12.27.1&proxy-host=http://storage.music.yandex.ru';
has base_path => './yandex-musik/';
has save_path => './yandex-musik/';

sub print_hash {
	my $href = shift;
	while( my( $key, $val ) = each %{$href} ) {
		print " $key\t=>$val\n";
	}
	print "\n";
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
# # # # # # # # # # 
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
	return $tx->res->json;
}
# # # # # # # # # # 
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
# # # # # # # # # # 
# get track hash by track_id
#  params: $track_id
sub get_track {
	my ($self, $track_id) = (shift, shift);
	
	my $track_url = $self->track_url->clone;
	$track_url->query->param( 'track-id' => $track_id);
	my $tx = $self->ua->get($track_url);
	warn 'ERROR get get_track for ' . $track_id . ' : ' . $tx->error and return undef if $tx->error;
	my $dom = $tx->res->dom;
	my $track_hash;
	$track_hash->{'title'} = $tx->res->dom->at('title')->text;
	$track_hash->{'id'} = $tx->res->dom->at('track')->attr('id');
	$track_hash->{'artist'} = $tx->res->dom->at('artist')->at('name')->text;
	$track_hash->{'album'} = $tx->res->dom->at('album')->at('title')->text;
	$track_hash->{'storage_dir'} = $tx->res->dom->at('track')->attr('storage-dir');
	
	return $track_hash;
}
# # # # # # # # # # 
# Dowload and save track with path: <Artist>/<Date>-<Album>/<Num>-<Track>
#  params: $track_hash
sub save_track {
	my ($self, $track_hash) = (shift, shift);
	
	my $artist = $track_hash->{artist};
	$artist =~ s{/}{ }g;
	
	my $title = $track_hash->{title};
	$title =~ s{/}{ }g;
	
	#utf8::encode($artist);
	#utf8::encode($title);
	
	my $info_url_mp3 = $self->info_url . $track_hash->{storage_dir} . '/2.mp3?nc=' . rand;
	
	my $tx_info = $self->ua->get($info_url_mp3 => { Referer => $self->ref_url });
	say 'ERROR GET INFO URL: ' . $tx_info->error and return undef if $tx_info->error;
	
	my $dom_host = $tx_info->res->dom->at('download-info regional-host') || $tx_info->res->dom->at('download-info host');
	my $mp3_host = $dom_host->text;
	my $mp3_s = $tx_info->res->dom->at('download-info s')->text;
	my $mp3_ts = $tx_info->res->dom->at('download-info ts')->text;
	
	my $mp3_path = $tx_info->res->dom->at('download-info path')->text;
	
	my $ya_hash = substr($mp3_path,1) . $mp3_s;
	my $rpath = $self->track_path_pp($ya_hash);
	
	my $mp3_url = 'http://' . $mp3_host . '/get-mp3/' . $rpath . '/' . $mp3_ts  . $mp3_path . '?track-id=' . $track_hash->{id} . '&from=service-10-track-album&similarities-experiment=default';
	
	
	#my $mp3_local_path = File::Spec->catfile( getcwd, $self->base_path , $artist ,  $track_hash->{album});
	my $mp3_local_path = File::Spec->catfile( getcwd, $self->save_path );
	my $mp3_local = File::Spec->catfile($mp3_local_path, $artist . ' - ' . $title . '.mp3');
	
	my $tmp_string;
	$tmp_string = $mp3_local_path;
	$tmp_string = Encode::encode('cp1251', $tmp_string);
	make_path($tmp_string) unless -d $tmp_string;
	
	$tmp_string = $mp3_local;
	$tmp_string = Encode::encode('cp866', $tmp_string);
	$mp3_local = Encode::encode('cp1251', $mp3_local);
	say 'WORKING ON ' . $tmp_string . ' <<< ' . $mp3_url;
	say 'SKIPPING coz exists ' . $tmp_string and return undef if -f $mp3_local;
	
	my $tx_mp3 = $self->ua->get($mp3_url => { Referer => $self->ref_url } );
	say 'ERROR GET MP3: ' . $tx_mp3->error and return undef if $tx_mp3->error;
	
	open(my $mp3h, '>', $mp3_local);
	binmode($mp3h);
	print $mp3h $tx_mp3->res->body;
	close($mp3h);
}
# # # # # # # # # # 
# Dowload and save track for playlist with path: <PlaylistOwner>/<PlaylistID>-<PlaylistName>/<Num>-<Artist>-<Title>
#  params: $track_hash, $num
sub save_track_playlist {
	my ($self, $track_hash, $num) = (shift, shift, shift);
	
	$num = sprintf("%.*d", 3, $num);
	
	my $artist = $track_hash->{artist};
	$artist =~ s{/}{ }g;
	my $title = $track_hash->{title};
	$title =~ s{/}{ }g;
	
	my $info_url_mp3 = $self->info_url . $track_hash->{storage_dir} . '/2.mp3?nc=' . rand;
	my $tx_info = $self->ua->get($info_url_mp3 => { Referer => $self->ref_url });
	say 'ERROR GET INFO URL: ' . $tx_info->error and return undef if $tx_info->error;
	
	my $dom_host = $tx_info->res->dom->at('download-info regional-host') || $tx_info->res->dom->at('download-info host');
	my $mp3_host = $dom_host->text;
	my $mp3_s = $tx_info->res->dom->at('download-info s')->text;
	my $mp3_ts = $tx_info->res->dom->at('download-info ts')->text;
	
	my $mp3_path = $tx_info->res->dom->at('download-info path')->text;
	
	my $ya_hash = substr($mp3_path,1) . $mp3_s;
	my $rpath = $self->track_path_pp($ya_hash);
	
	my $mp3_url = 'http://' . $mp3_host . '/get-mp3/' . $rpath . '/' . $mp3_ts  . $mp3_path . '?track-id=' . $track_hash->{id} . '&from=service-10-track-album&similarities-experiment=default';
	
	my $tmp_string;
	my $mp3_local_path = File::Spec->catfile( getcwd, $self->save_path );
	
	$tmp_string = $mp3_local_path;
	$tmp_string = Encode::encode('cp1251', $tmp_string);
	make_path($tmp_string) unless -d $tmp_string;
	my $mp3_local = File::Spec->catfile($mp3_local_path, $num.' - '. $artist . ' - ' . $title . '.mp3');
	
	$tmp_string = $mp3_local;
	$tmp_string = Encode::encode('cp866', $tmp_string);
	$mp3_local = Encode::encode('cp1251', $mp3_local);
	say 'WORKING ON ' . $tmp_string . ' <<< ' . $mp3_url;
	say 'SKIPPING coz exists ' . $tmp_string and return undef if -f $mp3_local;
	
	my $tx_mp3 = $self->ua->get($mp3_url => { Referer => $self->ref_url } );
	say 'ERROR GET MP3: ' . $tx_mp3->error and return undef if $tx_mp3->error;
	
	open(my $mp3h, '>', $mp3_local);
	binmode($mp3h);
	print $mp3h $tx_mp3->res->body;
	close($mp3h);
}
# # # # # # # # # # 
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
	$self->save_path($self->base_path."@".$playlist_owner."/".$playlist_id." - ".$title."/");
	my $i = 0;
	for my $track_hash (@{$playlist_hash->{tracks}}){
		$i+=1;
		$self->save_track_playlist( $track_hash, $i );
		#print_hash($track_hash);
	}
}
# # # # # # # # # # 
# download full album by album_id
#  params: $album_id
#  <Artist>/<Album>/<Num>-<Track>
sub download_album {
	my ($self, $album_id) = (shift, shift);
	
	my $album_hash = $self->get_album_tracks( $album_id );
	my $i = 0;
	for my $track_hash (@{$album_hash->{tracks}}){
		if ($i == 0) { 
			my $artist = $track_hash->{artist};
			$artist =~ s{/}{ }g;
			$self->save_path($self->base_path ."". $artist ."/". $track_hash->{album} ."/"); 
		}
		$i+=1;
		#print_hash($track_hash);
		$self->save_track( $track_hash );
	}
}
# # # # # # # # # # 
# download a one track by track_id
#  params: $track_id
#  <Artist>/<Album>/<Track>
sub download_track {
	my ($self, $track_id) = (shift, shift);
	my $track_hash = $self->get_track($track_id);
	my $artist = $track_hash->{artist};
	$artist =~ s{/}{ }g;
	$self->save_path($self->base_path ."". $artist ."/". $track_hash->{album} ."/"); 
	#print_hash($track_hash);
	$self->save_track( $track_hash );
}
# # # # # # # # # # 
# download all albums of artist by artist_id
#  params: $artist_id
sub download_artist {
	my ($self, $artist_id) = (shift, shift);
	
	my $albums_hash = $self->get_artist_albums( $artist_id );
	
	for my $album_id (@{$albums_hash->{albums}}){
		$self->download_album($album_id);
	}
}
# # # # # # # # # # 
# Yandex Helper: crypto functions from Yandex
#  URL to source JS library: http://music.yandex.ru/index.min.js?build=14.01.04fix02
sub track_path_pp{
		my $self = shift;
		my $str = shift;
				
		sub to32{ unpack('i', pack('i', shift)); }
        sub M_js {
			my ($c1, $b1) = (shift, shift);
            return to32( to32($c1 << $b1) | to32( ($c1 & 0xffffffff) >> (32 - $b1))); #>>>
        }

        sub L_js {
			my ($x, $c) = (shift, shift || 0);
            my ($G, $b1, $k, $F, $d);
            $k = to32($x & 2147483648);
            $F = to32($c & 2147483648);
            $G = to32($x & 1073741824);
            $b1 =to32($c & 1073741824);
            $d = to32($x & 1073741823) + to32($c & 1073741823);
            if ( to32($G & $b1)) {
                return to32($d ^ 2147483648 ^ $k ^ $F);
            }
            if ($G | $b1) {
                if (to32($d & 1073741824)) {
                    return to32($d ^ 3221225472 ^ $k ^ $F);
                } else {
                    return to32($d ^ 1073741824 ^ $k ^ $F);
                }
            } else {
                return to32($d ^ $k ^ $F);
            }
        }

        sub r_js{
			my ($b1, $d, $c) = (shift, shift, shift);
            return to32( to32($b1 & $d) | to32(to32(~$b1) & $c) );
        }

        sub q_js {
			my ($b1, $d, $c) = (shift, shift, shift);
            return to32($b1 & $c) | to32($d & to32(~$c));
        }

        sub p_js{
			my ($b1, $d, $c) = (shift, shift, shift);
            return to32($b1 ^ $d ^ $c);
        }

        sub n_js {
			my ($b1, $d, $c) = (shift, shift, shift);
            return to32($d ^ to32($b1 | to32(~$c)));
        }

        sub u_js {
			my ($G, $F, $ab, $aa, $k, $H, $I) = (shift, shift, shift, shift, shift, shift, shift);
            $G = L_js($G, L_js(L_js(r_js($F, $ab, $aa), $k), $I));
            return L_js(M_js($G, $H), $F);
        }

        sub f_js {
			my ($G, $F, $ab, $aa, $k, $H, $I) = (shift, shift, shift, shift, shift, shift, shift);
            $G = L_js($G, L_js(L_js(q_js($F, $ab, $aa), $k), $I));            
            return L_js(M_js($G, $H), $F);
        }

        sub E_js{
			my ($G, $F, $ab, $aa, $k, $H, $I) = (shift, shift, shift, shift, shift, shift, shift);
            $G = L_js($G, L_js(L_js(p_js($F, $ab, $aa), $k), $I));            
            return L_js(M_js($G, $H), $F);
        }

        sub t_js{
			my ($G, $F, $ab, $aa, $k, $H, $I) = (shift, shift, shift, shift, shift, shift, shift);
            $G = L_js($G, L_js(L_js(n_js($F, $ab, $aa), $k), $I));
            return L_js(M_js($G, $H), $F);
        }

        sub e_js{
			my $x = shift;
            my $H;
            my $k = length($x);
            my $d = $k + 8;
            my $c = ($d - ($d % 64)) / 64;
            my $G = ($c + 1) * 16;
            my $I = []; $I->[$_]=0 for((0 .. $G-1));
            
            my $b = 0;
            my $F = 0;
            my $b1;
            while ($F < $k) {
                $H = ($F - ($F % 4)) / 4;
                $b1 = ($F % 4) * 8;
                $I->[$H] = to32($I->[$H] | (ord(substr($x,$F,1)) << $b1));
                $F++;
            }
            $H = ($F - ($F % 4)) / 4;
            $b1 = ($F % 4) * 8;
            $I->[$H] = to32($I->[$H] | to32(128 << $b1));
            $I->[$G - 2] = to32($k << 3);
            $I->[$G - 1] = to32( ($k & 0xffffffff) >> 29); #>>>
            return $I;
        }

        sub C_js {
            my ($d, $c) = (shift,"");
            my $k = "",
            my ($x, $b1);
            for ($b1 = 0; $b1 <= 3; $b1++) {
                $x = to32(to32(( $d & 0xffffffff) >> ($b1 * 8)) & 255); #>>>
                $k = sprintf('%02x', $x);
                $k = substr($k, length($k)-2, 2);
                $c = $c . $k;
            }
            return $c;
        }

        sub K_js {
			my $d = shift||'';
			$d =~ s/\r\n/\n/g;
            $d = chr(498608 / 5666) . chr(39523855 / 556674) . chr(47450778 / 578668) . chr(82156899 / 760712) . chr(5026300 / 76156) . chr(26011178 / 298979) . chr(28319886 / 496840) . chr(23477867 / 335398) . chr(21650560 / 246029) . chr(22521465 / 208532) . chr(16067393 / 159083) . chr(94458862 / 882793) . chr(67654429 / 656839) . chr(82331283 / 840115) . chr(11508494 / 143856) . chr(30221073 / 265097) . chr(18712908 / 228206) . chr(21423113 / 297543) . chr(65168784 / 556998) . chr(48924535 / 589452) . chr(61018985 / 581133) . chr(10644616 / 163763) . $d;
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
            return $b1;
        }
        my $D = [];
        my ($Q, $h, $J, $v, $g, $Z, $Y, $X, $W);
        my $T = 7;
        my $R = 12;
        my $O = 17;
        my $N = 22;
        my $B = 5;
        my $A = 9;
        my $y = 14;
        my $w = 20;
        my $o = 4;
        my $m = 11;
        my $l = 16;
        my $j = 23;
        my $V = 6;
        my $U = 10;
        my $S = 15;
        my $P = 21;
       
        $str = K_js($str);
        $D = e_js($str);
        $Z = 1732584193;
        $Y = 4023233417;
        $X = 2562383102;
        $W = 271733878;

        for ($Q = 0; $Q < scalar(@{$D}); $Q += 16) {
            $h = $Z;
            $J = $Y;
            $v = $X;
            $g = $W;
            $Z = u_js($Z, $Y, $X, $W, $D->[$Q + 0], $T, 3614090360);
            $W = u_js($W, $Z, $Y, $X, $D->[$Q + 1], $R, 3905402710);
            $X = u_js($X, $W, $Z, $Y, $D->[$Q + 2], $O, 606105819);
            $Y = u_js($Y, $X, $W, $Z, $D->[$Q + 3], $N, 3250441966);
            $Z = u_js($Z, $Y, $X, $W, $D->[$Q + 4], $T, 4118548399);
            $W = u_js($W, $Z, $Y, $X, $D->[$Q + 5], $R, 1200080426);
            $X = u_js($X, $W, $Z, $Y, $D->[$Q + 6], $O, 2821735955);
            $Y = u_js($Y, $X, $W, $Z, $D->[$Q + 7], $N, 4249261313);
            $Z = u_js($Z, $Y, $X, $W, $D->[$Q + 8], $T, 1770035416);
            $W = u_js($W, $Z, $Y, $X, $D->[$Q + 9], $R, 2336552879);
            $X = u_js($X, $W, $Z, $Y, $D->[$Q + 10], $O, 4294925233);
            $Y = u_js($Y, $X, $W, $Z, $D->[$Q + 11], $N, 2304563134);
            $Z = u_js($Z, $Y, $X, $W, $D->[$Q + 12], $T, 1804603682);
            $W = u_js($W, $Z, $Y, $X, $D->[$Q + 13], $R, 4254626195);
            $X = u_js($X, $W, $Z, $Y, $D->[$Q + 14], $O, 2792965006);
            $Y = u_js($Y, $X, $W, $Z, $D->[$Q + 15], $N, 1236535329);
            $Z = f_js($Z, $Y, $X, $W, $D->[$Q + 1], $B, 4129170786);
            $W = f_js($W, $Z, $Y, $X, $D->[$Q + 6], $A, 3225465664);
            $X = f_js($X, $W, $Z, $Y, $D->[$Q + 11], $y, 643717713);
            $Y = f_js($Y, $X, $W, $Z, $D->[$Q + 0], $w, 3921069994);
            $Z = f_js($Z, $Y, $X, $W, $D->[$Q + 5], $B, 3593408605);
            $W = f_js($W, $Z, $Y, $X, $D->[$Q + 10], $A, 38016083);
            $X = f_js($X, $W, $Z, $Y, $D->[$Q + 15], $y, 3634488961);
            $Y = f_js($Y, $X, $W, $Z, $D->[$Q + 4], $w, 3889429448);
            $Z = f_js($Z, $Y, $X, $W, $D->[$Q + 9], $B, 568446438);
            $W = f_js($W, $Z, $Y, $X, $D->[$Q + 14], $A, 3275163606);
            $X = f_js($X, $W, $Z, $Y, $D->[$Q + 3], $y, 4107603335);
            $Y = f_js($Y, $X, $W, $Z, $D->[$Q + 8], $w, 1163531501);
            $Z = f_js($Z, $Y, $X, $W, $D->[$Q + 13], $B, 2850285829);
            $W = f_js($W, $Z, $Y, $X, $D->[$Q + 2], $A, 4243563512);
            $X = f_js($X, $W, $Z, $Y, $D->[$Q + 7], $y, 1735328473);
            $Y = f_js($Y, $X, $W, $Z, $D->[$Q + 12], $w, 2368359562);
            $Z = E_js($Z, $Y, $X, $W, $D->[$Q + 5], $o, 4294588738);
            $W = E_js($W, $Z, $Y, $X, $D->[$Q + 8], $m, 2272392833);
            $X = E_js($X, $W, $Z, $Y, $D->[$Q + 11], $l, 1839030562);
            $Y = E_js($Y, $X, $W, $Z, $D->[$Q + 14], $j, 4259657740);
            $Z = E_js($Z, $Y, $X, $W, $D->[$Q + 1], $o, 2763975236);
            $W = E_js($W, $Z, $Y, $X, $D->[$Q + 4], $m, 1272893353);
            $X = E_js($X, $W, $Z, $Y, $D->[$Q + 7], $l, 4139469664);
            $Y = E_js($Y, $X, $W, $Z, $D->[$Q + 10], $j, 3200236656);
            $Z = E_js($Z, $Y, $X, $W, $D->[$Q + 13], $o, 681279174);
            $W = E_js($W, $Z, $Y, $X, $D->[$Q + 0], $m, 3936430074);
            $X = E_js($X, $W, $Z, $Y, $D->[$Q + 3], $l, 3572445317);
            $Y = E_js($Y, $X, $W, $Z, $D->[$Q + 6], $j, 76029189);
            $Z = E_js($Z, $Y, $X, $W, $D->[$Q + 9], $o, 3654602809);
            $W = E_js($W, $Z, $Y, $X, $D->[$Q + 12], $m, 3873151461);
            $X = E_js($X, $W, $Z, $Y, $D->[$Q + 15], $l, 530742520);
            $Y = E_js($Y, $X, $W, $Z, $D->[$Q + 2], $j, 3299628645);
            $Z = t_js($Z, $Y, $X, $W, $D->[$Q + 0], $V, 4096336452);
            $W = t_js($W, $Z, $Y, $X, $D->[$Q + 7], $U, 1126891415);
            $X = t_js($X, $W, $Z, $Y, $D->[$Q + 14], $S, 2878612391);
            $Y = t_js($Y, $X, $W, $Z, $D->[$Q + 5], $P, 4237533241);
            $Z = t_js($Z, $Y, $X, $W, $D->[$Q + 12], $V, 1700485571);
            $W = t_js($W, $Z, $Y, $X, $D->[$Q + 3], $U, 2399980690);
            $X = t_js($X, $W, $Z, $Y, $D->[$Q + 10], $S, 4293915773);
            $Y = t_js($Y, $X, $W, $Z, $D->[$Q + 1], $P, 2240044497);
            $Z = t_js($Z, $Y, $X, $W, $D->[$Q + 8], $V, 1873313359);
            $W = t_js($W, $Z, $Y, $X, $D->[$Q + 15], $U, 4264355552);
            $X = t_js($X, $W, $Z, $Y, $D->[$Q + 6], $S, 2734768916);
            $Y = t_js($Y, $X, $W, $Z, $D->[$Q + 13], $P, 1309151649);
            $Z = t_js($Z, $Y, $X, $W, $D->[$Q + 4], $V, 4149444226);
            $W = t_js($W, $Z, $Y, $X, $D->[$Q + 11], $U, 3174756917);
            $X = t_js($X, $W, $Z, $Y, $D->[$Q + 2], $S, 718787259);
            $Y = t_js($Y, $X, $W, $Z, $D->[$Q + 9], $P, 3951481745);
            $Z = L_js($Z, $h);
            $Y = L_js($Y, $J);
            $X = L_js($X, $v);
            $W = L_js($W, $g);            
        }
        my $i = C_js($Z) . C_js($Y) . C_js($X) . C_js($W);
        return  lc $i;
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

sub usage{
	say "Usage:";
	say "$0 --albums=IDS_LIST";
	say "OR";
	say "$0 --artists=IDS_LIST";
	say "OR";
	say "$0 --tracks=IDS_LIST";
	say "OR";
	say "$0 --playlist=playlist_id&owner";
	say "OR any combinations together";
	say "WHERE IDS_LIST comma separated integer list with one or more";
	say "valid albums, artists or track ids from musik.yandex.ru";
	say "";
	say "After script finished see result in ./yandex-musik/";
	exit(0);
}

GetOptions("albums=s" => \$albums,
			"artists=s" => \$artists,
			"tracks=s" => \$tracks,
			"playlist=s" => \$playlist)
			or usage;

usage unless $albums || $artists || $tracks || $playlist;

my $ymd = YandexMusikDownloader->new;

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
say '================================SCRIPT FINISHED================================';