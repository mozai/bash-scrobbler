#!/bin/bash
# command-line posting info to Last.FM's scrobbler API

# You should get your own API_KEY and API_SECRET
# from https://www.last.fm/api/account/create
# and write them into CFGFILE like so:
# API_KEY=oicu812
# API_SECRET=foobarbaazquux

# TODO: safer way to read CFGFILE than "source CFGFILE"
# TODO: what is the API_URL for libre.fm?
# TODO: sensing too-frequent posting 
# TODO: avoid redundant posting; GET method=track.updateNowPlaying first?
# TODO: optional love/unlove toggle

CFGFILE=$HOME/.config/bash-scrobbler
API_URL="https://ws.audioscrobbler.com/2.0/"

mk_API_SIG(){ 
	local payload
	payload=$(for i in "$@"; do echo "${i/=/}"; done |sort |tr -d '\n')"${API_SECRET}"
	payload=$(echo -n "$payload" | md5sum)
	echo "${payload/ */}"
}

init(){ if [ -n "$TOKEN" ]; then init_2; else init_1; fi; }

init_1(){
	local tmpfile url
	tmpfile=$(mktemp)
	:> "$CFGFILE" && chmod 600 "$CFGFILE"
	mkdir -p "$(dirname "$CFGFILE")"
	echo "# for use with bash-scrobbler"
	echo "API_KEY=${API_KEY}" >>"$CFGFILE"
	echo "API_SECRET=${API_SECRET}" >>"$CFGFILE"
	curl -s "${API_URL}?method=auth.gettoken&api_key=${API_KEY}&format=json" >"$tmpfile"
	TOKEN=$(<"$tmpfile" tr '\n' ' ' |sed -nr 's/.*"token":\s*"([^"]*)".*/\1/p')
	if [ -n "$TOKEN" ]; then
		echo "TOKEN=${TOKEN}" >>"$CFGFILE"
		url="https://www.last.fm/api/auth/?api_key=${API_KEY}&token=${TOKEN}"
		xdg-open "$url"
		echo "I attempted to open $url"
		echo "Please use it to log-in to Last.fm and permit me to scrobble, then"
		echo "launch $0 init again to complete the process."
	else
		cat >&2 "$tmpfile"
		return 1
	fi
}

init_2(){
	tmpfile=$(mktemp)
	local -a params
	params=( "api_key=${API_KEY}" "method=auth.getSession" "token=${TOKEN}" )
	API_SIG=$(mk_API_SIG "${params[@]}")
	curl -s "${API_URL}?api_key=${API_KEY}&method=auth.getSession&token=${TOKEN}&api_sig=${API_SIG}&format=json" >"$tmpfile"
	SESSION_KEY=$(<"$tmpfile" sed -nr 's/.*"key":\s*"([^"]*)".*/\1/p')
	if [ -n "$SESSION_KEY" ]; then
		echo "SESSION_KEY=${SESSION_KEY}" >>"$CFGFILE"
		echo "Init completed. You may now use this program to scrobble tracks."
	else
		echo >&2 "auth.getSession failed"
		cat >&2 "$tmpfile"
		return 1
	fi 
}

scrobble(){
	local now tmpfile params http_params i api_sig
	if [ -z "$2" ]; then
		echo >&2 "need \"artist name\" and \"song name\" as parameters"
		return 1;
	fi
	tmpfile=$(mktemp)
	now=$(printf '%(%s)T')
	local -a params
	params=( "api_key=${API_KEY}" )
	params+=( "sk=${SESSION_KEY}" )
	params+=( "method=track.scrobble" )
	[ -n "$3" ] && params+=( "album=$3" )
	params+=( "artist=$1" )
	params+=( "timestamp=$now" )
	params+=( "track=$2" )
	http_params=()
	for i in "${params[@]}"; do
		http_params+=( "--data-urlencode" "$i" )
	done
	api_sig=$(mk_API_SIG "${params[@]}")
	http_params+=("--data" "api_sig=${api_sig}")
	curl -s -m3 -X POST "https://ws.audioscrobbler.com/2.0/" \
		-H "Connection: close" "${http_params[@]}" >"$tmpfile"
	if ! grep -q '<lfm status="ok">' "$tmpfile"; then
		echo >&2 "track.scrobble failed"
		cat >&2 "$tmpfile"
		rm "$tmpfile"
		return 1
	fi
	[ -t 0 ] && cat "$tmpfile"  # see the response if used on a tty
	rm "$tmpfile"
}

usage(){
	echo >&2 "Usage: $0 [init | artistname songname [albumname] ]"
	echo >&2 "Usage: $0 artist words - title words [ - album words ]"
	echo >&2 "    Tell Last.FM what you're currently listening to."
}


# -- main
if ! command -v curl >/dev/null; then
	echo >&2 "I need curl to do https communication; aborting."
	exit 1
fi
# shellcheck disable=SC1090
source "$CFGFILE"  # TODO test if it's safe before launching it
if [ -z "$SESSION_KEY" ]; then
	echo >&2 "Missing session key; did you try 'init' yet?"
	usage
	exit 1;
fi

# parse args
#  $0 "artist name" "song name"
#  $0 "artist name" "song name" "album name"
#  $0 artist name - song name
#  $0 artist name - song name - album name
declare founddash
for f in "$@"; do
	if [ "$f" == "-" ]; then
		founddash=1
		break
	fi
done
if [ -n "$founddash" ]; then
	declare hopper artist title album
	for f in "$@"; do
		if [ "$f" == "-" ] && [ -z "$artist" ]; then
			artist=${hopper% }
			hopper=""
		elif [ "$f" == "-" ] && [ -z "$title" ]; then
			title=${hopper% }
			hopper=""
		else
			hopper+="$f "
		fi
	done
	if [ -z "$title" ]; then
		title=${hopper% }; hopper=""
	else
		album=${hopper% }
	fi
else
	if [ $# -eq 2 ] || [ $# -eq 3 ]; then
		artist=$1; title=$2; album=$3;
	else
		usage;
		exit 1
	fi
fi

if [ $# -eq 1 ] && [ "$1" == "init" ]; then
	init;
elif [ -n "$title" ]; then
	scrobble "$artist" "$title" "$album"
else
	usage
	exit 1
fi
