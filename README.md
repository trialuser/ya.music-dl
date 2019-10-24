Downloader for Yandex.Music
=============

It allows to download tracks, playlists, albums from the online-service http://music.yandex.ru/

Installation:
-------

    cpan install URI::Escape
    cpan install IO::Socket::SSL
    cpan install Mojo
    cpan install MP3::Tag
    
    Note: It also requires installed: perl, libperl-dev, libyaml-perl

Usage
-------


### Console output:

    Usage: ya.music-dl.pl [command] [options]
    
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
         following format: LOGIN:PASSWORD@SERVER:PORT, i.e.: "user:secure@127.0.0.1:8080"
    
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
    -lc or --locale_console
        - set the codepage for system console (for output messages)
    -lfs or --locale_filesystem
        - set the codepage for filenames
     --help
         - print this help
    
     Samples:
         ya.music-dl.pl --albums=295708,295709,295710 -c --dir=./
         ya.music-dl.pl --artists=3120,79215 --proxy="192.168.50.1:8080"
         ya.music-dl.pl --artists=3120,79215 --cover --tags_only
         ya.music-dl.pl --tracks=2749751,2295002,1710808,1710811,1710816,2295010,2758009 -c -ns --dir="./Queen/favorites/"
         ya.music-dl.pl --playlist="1008&ya-playlist" --login=my_yandex_login --password=secret
         ya.music-dl.pl --tracks=2749751,2295002,1710808,1710811,1710816,2295010,2758009 -c -ns --dir="./MyPlaylists/" --cp=1 --cp-name=Queen
         ya.music-dl.pl --playlist="1042&ya-playlist" -c -cp=1

### Hints:

    Yandex doesn't allow to download music from non-russian countries. You may download 
         the tracks throught the proxy: just google and use any free proxy from RU, UA, BY 
         locations... eg. from here: http://spys.ru/free-proxy-list/RU/
      Sample:
         ya.music-dl.pl --artists=3120,79215 --proxy="195.189.123.134:3128"
