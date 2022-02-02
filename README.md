bash-scrobbler
=============
Made so I could provoke my favourite music player Music On Console (MOC)
to participate in the music panopticon that is Last.FM


Install
-------
- have bash and curl, and the other binutils like grep, sed, tr.
- have a webbrowser handy with a last.fm account logged-in.
- get a [Last.FM API key](https://www.last.fm/api/account/create)
- write them into ~/.config/bash-scrobbler like so:
  ```
  API_KEY=oicu812
  API_SECRET=foobarbaazquux
  ```
- `bash-scrobbler init` to start the process of getting a session key.
  It will attempt to open a webbrowser, but also print the URL so you can
  load it up youself.

### Using with MOC
- edit $HOME/.moc/config to add these two lines:  
  ```
  OnSongChange = "/path/to/bash-scrobbler %a %t %r"
  RepeatSongChange = "yes"
  ```
- `mocp -x` to force a restart of the daemon after making config changes.

MOC's "OnSongChange" feature isnt documented in the readme files nor
man pages.  To save you reading [the source
code](https://github.com/jonsafari/mocp/blob/master/server.c#L523-L574),
here are the % macros: `%a artist %r album %t title %n track %f filename
%D duration(seconds) %d duration(MM:SS)`


Usage
-----
After a successful init, and the config settings are stowed in ~/.config/bash-scrobbler:

`bash-scrobbler "Toby Fox" "MeGaLoVania" "Homestuck Vol. 6: Heir Transparent"`  
`bash-scrobbler "Boa" "Duvet"`  
`bash-scrobbler "Battery" "The Chauffeur" "Newer Wave"`  


Todo
----
- optional third parameter for album name
- safer way to read CFGFILE than "source CFGFILE"
- option to post to libre.fm instead of last.fm; maybe both?
- sense too-frequent posting 
- avoid redundant posting; GET method=track.updateNowPlaying first?
- sense if user is listening to an http(s) stream, and add the
  Last.FM parmeter "chosenByUser=0"
- option for love/unlove toggle


Acknowledgements
----------------
I went looking for Pachanka's
[moc-scrobbler](https://goto.pachanka.org/moc-scrobbler/), they said
they moved from github to gitlab... but gitlab said pachanka's persona
no grata, so no moc-scrobbler.  Had to make my own.

