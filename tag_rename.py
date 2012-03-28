#!/usr/bin/python3

import sys, subprocess, os, re

def simplify(fname):

    '''Removes unwanted characters from strings'''

    result = fname.lower()
    for k, v in {
        '[åä]': 'a',
        '[öø]': 'o',
        '[.,:;"?!\']': '',
        '[ \t()\\[\\]\\{\\}/\\\\+&]': '_'
        }.items():
        result = re.sub(k, v, result)
    return result

def generate_dir_name(tags_dict):

    '''Suggests a new name for a directory based on the tags supplied'''

    artist = album = None
    reqs =  ('ARTIST', 'ALBUM')  #These are needed
    for fname, tags in tags_dict.items():
        for req in reqs:
            if req not in tags:
                raise AssertionError(req + ' was not found for ' + fname)
        this_artist = tags['ARTIST']
        if artist and artist != this_artist:
            raise AssertionError('artist mismatch for ' + fname + ': "'
                    + this_artist + '" != "' + artist + '"')
        artist = this_artist
        this_album = tags['ALBUM']
        if album and album != this_album:
            raise AssertionError('album mismatch for ' + fname + ': "'
                    + this_album + '" != "' + album + '"')
        album = this_album
    return simplify(artist + '-' + album)

def generate_file_name(tags):

    '''Suggests a new file name based on the tags supplied'''

    for req in ('TRACKNUMBER', 'TITLE'):
        if req not in tags:
            raise AssertionError('no ' + req + '!')

    # Some files have TRACKNUMBER="03/12", remove the dash and everything
    # following it.
    tn = re.sub(r'/.*', '', tags['TRACKNUMBER'])
    # pad with a zero for proper left alignment of file numbers.
    if len(tn) == 1:
        tn = '0' + tn

    title = simplify(tags['TITLE'])
    return tn + '-' + title + '.flac'

def parse_tags(metaflac_output):

    '''Turns the output of metaflac --export-tags-to, eg:

            ALBUM=We Were Exploding Anyway
            ARTIST=65daysofstatic
            COMMENT=Japanese Release (With a Bonus Track)
            DATE=2010
            GENRE=Post-Rock
            TITLE=Mountainhead
            TRACKNUMBER=01

        into a dict:

            {'ALBUM': 'We Were Exploding Anyway',
            'ARTIST': '65daysofstatic',
            'COMMENT': 'Japanese Release (With a Bonus Track)',
            'DATE': '2010',
            'GENRE': 'Post-Rock',
            'TITLE': 'Mountainhead',
            'TRACKNUMBER': '01'}
    '''
    return {t[0].upper(): t[1] for t in (
        v.split('=') for v in metaflac_output.split('\n')
        if '=' in v)} # There may be blank lines

def grab_tags(fname):
    metaflac_output = str(subprocess.check_output([
        'metaflac',
        '--export-tags-to=-',
        fname]), 'utf-8')
    return parse_tags(metaflac_output)

def grab_subfile_tags(dirname):
    fnames = (os.path.normpath(dirname) + '/' + fname
            for fname in os.listdir(dirname)
            if fname.endswith('.flac'))
    return {fname: grab_tags(fname) for fname in fnames}

if __name__ == '__main__':

    # TODO: when moving to python3.2
    #import argparse
    #parser = argparse.ArgumentParser()
    #parser.add_opt('-t', '--test')
    #parser.add_opt('-v', '--verbose')
    #args = parser.parse_args()

    import optparse, shutil
    parser = optparse.OptionParser()
    parser.add_option('-t', '--test', help='don\'t rename, just test it',
            action='store_true')
    parser.add_option('-v', '--verbose', help='print a lot of stuff',
            action='store_true')
    options, args = parser.parse_args()
    verbose = options.verbose
    test = options.test

    renames = []
    for fname in args:
        is_dir = os.path.isdir(fname)
        is_file = os.path.isfile(fname)
        if not (is_dir or is_file):
            raise ValueError('What is ' + fname + '?')
        target_dir = os.path.dirname(os.path.normpath(fname))
        target_dir = target_dir + '/' if target_dir else ''
        if os.path.isdir(fname):
            renames.append((fname,
                target_dir + generate_dir_name(grab_subfile_tags(fname))))
        if (os.path.isfile(fname)):
            renames.append((fname,
                target_dir + generate_file_name(grab_tags(fname))))

    for rename in renames:
        if verbose:
            print('"' + rename[0] + '" -> "' + rename[1] + '"')
        if not test:
            shutil.move(rename[0], rename[1])

