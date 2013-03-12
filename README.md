tango_metadata
==============

Tool for looking up metadata for tangos from https://tango.info/ and http://www.tango-dj.at/database/

File organization
-----------------

Put your tango files in a main folder with just them, and inside of that separate them with:

1. A folder with the name of the orchestra, exactly as it is found in https://tango.info/. For example, Lucio Demare's Orquesta Típica should be called just "Lucio Demare", as found in https://tango.info/LucioDemar.

2. Inside the orchestra's folder, name your files with the format as in the following examples: "1942 Ribereña (Juan Carlos Miranda).m4a", if it has a singer (in this case, Juan Carlos Miranda); or "1938 La esquina.m4a" if it's an instrumental track. The m4a extension is just and example: any common audio format will work.

An example "tango" folder and a few files are provided for guidance.

Configuration
-----------------

Before you install the gem, make sure to have [FFmpeg](http://www.ffmpeg.org/) installed.

Then, in a shell window, inside the tango_metadata folder, run:

```
gem install bundler
bundle install
```

Usage
-----

In a shell window, inside the tango_metadata folder, run:

```
bundle exec ruby set_tango_metadata.rb /your/main/folder/of/choice
```
