tango_id3
=========

Tool for looking up ID3 tags for tangos from https://tango.info/

Pre-configuration
-----------------

Put your tango files in a main folder with just them, and inside of that separate them with:

1. A folder with the name of the orchestra, exactly as it is found in https://tango.info/. For example, Lucio Demare's Orquesta Típica should be called just "Lucio Demare", as found in https://tango.info/LucioDemar.

2. Inside the orchestra's folder, name your files with the format as in the following examples: "1942 Ribereña (Juan Carlos Miranda).m4a", if it has a singer (in this case, Juan Carlos Miranda); or "1938 La esquina.m4a" if it's an instrumental track. The m4a extension is just and example: any common audio format will work.

An example "tango" folder and 2 file are provided for guidance.

Usage
-----

In a shell window, run:

```
ruby set_tango_id3.rb /your/main/folder/of/choice
```
